# frozen_string_literal: true

require "readline"
require "strscan"

require "msh/error"
require "msh/logger"
require "msh/token"
require "msh/scanner"

module Msh
  # The lexer breaks down input text into a series of tokens.
  #
  # By definition, a token contains a type (which token), and a value (the
  # matched string). They also usually contain line and column number
  # information, and other metadata as well. See {Msh::Token}.
  #
  # A lexer operates like so:
  #
  # - As long as input is available, grab the next character
  # - Attempt to match a token
  #
  # The match attempt logic is {#next_token}, which is just a a big switch
  # statement on the next character, more or less.
  #
  # Note: this lexer is lossless, i.e, the completed tokens contain the entire
  # source code, including tabs, spaces, and comments.
  class Lexer
    include Msh::Logger

    class Error < Msh::Error; end

    # TODO: there's def more of these
    NON_WORD_CHARS = [
      "\0",
      "#",
      " ",
      "\t",
      "\n",
      "&",
      "|",
      "<", ">",
      "(", ")",
      "{", "}",
      ";"
    ].freeze

    # @return [Integer] the current line
    attr_reader :line

    # @return [Integer] the current column
    attr_reader :column

    # @param input [String]
    def initialize input
      @scanner = Scanner.new input
      @tokens  = []
      @token   = Token.new
    end

    # Run the lexer on the input until we collect all the tokens.
    #
    # @return [Array<Token>] all tokens in the input
    def tokens
      next_token until @tokens.last&.type == :EOF
      @tokens
    end

    # # @return [Token, nil] the next token, or nil if not complete or at EOF
    def next_token
      reset_and_set_start

      case advance
      when "\0"
        error "out of input" if @tokens.last&.type == :EOF
        # set_token_start
        @token.type = :EOF
      when "#"
        case @scanner.peek
        when "{"
          consume_interpolation
        else
          @token.type = :COMMENT
          advance until ["\n", "\0"].include? @scanner.current_char
        end
      when " ", "\t" # skip whitespace
        consume_whitespace
      when "\n" # newlines
        @token.type = :NEWLINE
      when ";"
        @token.type = :SEMI
      when "{"
        @token.type = :LEFT_BRACE
      when "}"
        @token.type = :RIGHT_BRACE
      when "("
        @token.type = :LEFT_PAREN
      when ")"
        @token.type = :RIGHT_PAREN
      when "!"
        @token.type = :BANG
      when "&"
        if @scanner.peek == "&"
          advance
          @token.type = :AND
        elsif @scanner.peek(2) == ">>"
          2.times { advance }
          @token.type = :AND_D_REDIRECT_RIGHT
        elsif @scanner.peek == ">"
          advance
          @token.type = :AND_REDIRECT_RIGHT
        else
          @token.type = :BG
        end
      when ">"
        consume_redir_right
      when "<"
        consume_redir_left
      when "|"
        case @scanner.peek
        when "|"
          advance
          @token.type = :OR
        when "&"
          advance
          @token.type = :PIPE_AND
        else
          @token.type = :PIPE
        end
      when "1".."9"
        advance while @scanner.peek.match?(/\d+/)

        if @scanner.peek == ">"
          advance
          consume_redir_right
        elsif @scanner.peek == "<"
          advance
          consume_redir_left
        else
          consume_word
        end
      else
        if @token.value          == "t" &&
           @scanner.peek(3)      == "ime"
          # TODO: `time -p` here? Pretty sure this needs to be handled by
          # the parser. Or some hideous lexer state here.
          #
          # That is, we need this for the `-p` option
          #
          # ```
          # 1. [TIME, "time"]
          # 2. [SPACE, "..."]
          # 3. [WORD, "-p"]
          # ```
          3.times { advance }
          @token.type = :TIME
        else
          consume_word
        end
      end

      return next_token if @token.type.nil?

      @tokens << @token.dup
      @token
    end

    # {#eof?} but in such a way that you still get true when the next token
    # is an EOF
    #
    # @param [Boolean] whether the last token is *not* an EOF
    def next?
      @tokens.last&.type != :EOF
    end

    # @return [Token, nil]
    def current_token
      @tokens.last
    end

    # Run the lexer interactively, i.e, run a loop and tokenize user input.
    def self.interactive
      while line = Readline.readline("lexer> ", true)&.chomp
        case line
        when "q", "quit", "exit"
          puts "goodbye! <3"
          return
        else
          begin
            puts Msh::Lexer.new(line).tokens
          rescue Error => e
            puts e.message
          end
        end
      end
    end

    # Run the lexer on a file, and print all of it's tokens.
    def self.lex_file filename
      puts new(File.read(filename)).tokens
    rescue Error => e
      puts e.message
    end

    # Run the lexer, either on all files passed to ARGV, or interactively, if
    # no files are supplied. Aborts program on error.
    def self.start args = ARGV
      return Msh::Lexer.interactive if args.size.zero?

      args.each do |file|
        raise Error, "#{file} is not a file!" unless File.file?(file)

        puts Lexer.new(File.read(file)).tokens
      end
    end

    private

    # Raise an error with helpful output.
    #
    # @raise [Error]
    def error msg = nil
      raise Error, "error at line #{@token.line}, " \
                   "column #{@token.column}: #{msg}"
    end

    def set_token_start
      @token.line = @scanner.line
      @token.column = @scanner.column
    end

    # nils out all of our current token's fields
    #
    # @param [Token]
    def reset_token
      @token.tap do |t|
        t.type   = nil
        t.value  = ""
        t.line   = nil
        t.column = nil
      end
    end

    def reset_and_set_start
      reset_token
      set_token_start
    end

    def advance
      c = @scanner.advance
      @token.value += c
      c
    end

    # Back the lexer up one character.
    #
    # @return [Integer] the current position index in input
    def backup
      c = @scanner.backup
      @token.value = @token.value[0...-1]
      c
    end

    # @note we've just seen a `#`
    #
    # Start at the `{` of a `#{...}`, gredily match a `}` such that we have
    # paired braces.
    #
    # ```
    # #{{} # fails, unterminated string interpolation at line 1, column 2
    # #{}} # `}` this will syntax error when we eventually eval it
    # ```
    #
    # this has the unfortunate consequence of treating the left and right
    # braces differently, as seen above. The only way to _actually_ fix this
    # is to parse the ruby expression inside the interpolation.
    def consume_interpolation
      line = @scanner.line
      col = @scanner.column - 1 # we already saw the `#`
      l_brace_stack = []

      while c = advance # loop until closing `}`
        case c
        when "{"
          l_brace_stack << c
        when "}"
          break if l_brace_stack.empty?

          l_brace_stack.pop
        end
        break if l_brace_stack.empty? || @scanner.eof?
      end

      if l_brace_stack.size.positive? # || c.nil? || eof?
        error <<~ERR
          unterminated string interpolation, expected `}` to complete `\#{` at line #{line}, column #{col}
        ERR
      end

      @token.type = :INTERP
      @token.column = col
      @token.line = line
    end

    # @note we've just seen either a ` ` or a `\t`
    def consume_whitespace
      @token.type = :SPACE
      return if @scanner.current_char == "\0"

      while @scanner.current_char == " " ||
            @scanner.current_char == "\t"
        advance
      end
    end

    # @note we've just seen a `>`
    def consume_redir_right
      case @scanner.peek
      when ">"
        advance
        @token.type = :APPEND_OUT
      when "|"
        advance
        @token.type = :NO_CLOBBER
      else
        if @scanner.peek == "&"
          advance
          advance while @scanner.peek.match? /\d+/
          @token.type = :DUP_OUT_FD
        else
          @token.type = :REDIRECT_OUT
        end
      end
    end

    # @note we've just seen a `<`
    def consume_redir_left
      case @scanner.peek
      when "&"
        if @scanner.peek(3).match? /&\d+-/
          3.times { advance }
          @token.type = :MOVE
        else
          advance
          advance while @scanner.peek.match? /\d+/
          @token.type = :DUP_IN_FD
        end
      when ">"
        advance
        @token.type = :OPEN_RW
      else
        @token.type = :REDIRECT_IN
      end
    end

    # @note we've just seen the first character of a WORD
    def consume_word
      advance until NON_WORD_CHARS.include?(@scanner.peek(1))
      @token.type = :WORD
    end
  end
end
