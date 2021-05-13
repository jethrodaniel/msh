require_relative "readline"
require_relative "errors"
require_relative "token"
require_relative "scanner"

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
  #
  # @example
  #   lexer = Msh::Lexer.new "a | b > c"
  #   tokens = [
  #     "[1:1-1][WORD, \"a\"]",
  #     "[1:2-2][SPACE, \" \"]",
  #     "[1:3-3][PIPE, \"|\"]",
  #     "[1:4-4][SPACE, \" \"]",
  #     "[1:5-5][WORD, \"b\"]",
  #     "[1:6-6][SPACE, \" \"]",
  #     "[1:7-7][REDIRECT_OUT, \">\"]",
  #     "[1:8-8][SPACE, \" \"]",
  #     "[1:9-9][WORD, \"c\"]",
  #     "[1:10-10][EOF, \"\\u0000\"]"
  #   ]
  #   lexer.tokens.map(&:to_s) == tokens #=> true
  class Lexer
    # TODO: there's def more of these
    NON_WORD_CHARS = [
      "\0",
      "#",
      " ",
      "=",
      "$",
      "\t",
      "\n",
      "&",
      "|",
      "<", ">",
      "(", ")",
      "{", "}",
      ";"
    ].freeze

    DIGITS = %(0 1 2 3 4 5 6 7 8 9).freeze

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
    # @return [Array<Msh::Token>] all tokens in the input
    def tokens
      next_token until @tokens.last&.type == :EOF
      @tokens
    end

    # @return [Token, nil] the next token, or nil if not complete or at EOF
    def next_token
      reset_and_set_start

      case advance
      when "\0"
        error "out of input" if @tokens.last&.type == :EOF
        # set_token_start
        @token.type = :EOF
      when "#"
        case @scanner.current_char
        when "{"
          consume_interpolation
        else
          @token.type = :COMMENT
          advance until ["\n", "\0"].include? @scanner.current_char
        end
      when "="
        @token.type = :EQ
      when "$"
        @token.type = :VAR
        advance until NON_WORD_CHARS.include? @scanner.current_char
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
        if @scanner.current_char == "&"
          advance
          @token.type = :AND
        elsif @scanner.peek(2) == ">>"
          2.times { advance }
          @token.type = :AND_D_REDIRECT_RIGHT
        elsif @scanner.current_char == ">"
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
        case @scanner.current_char
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
        advance while DIGITS.include?(@scanner.current_char)

        case @scanner.current_char
        when ">"
          advance
          consume_redir_right
        when "<"
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
        elsif @token.value == "i" && @scanner.current_char == "f"
          advance
          @token.type = :IF
        elsif @token.value == "t" && @scanner.peek(3) == "hen"
          3.times { advance }
          @token.type = :THEN
        elsif @token.value == "e" && @scanner.peek(3) == "lse"
          3.times { advance }
          @token.type = :ELSE
        elsif @token.value == "e" && @scanner.peek(2) == "nd"
          2.times { advance }
          @token.type = :END
        else
          consume_word
        end
      end

      return next_token if @token.type.nil?

      @token.type = :LAST_STATUS if @token.type == :VAR && @token.value == "$?"

      @tokens << @token.dup.freeze
      @token
    end

    # {Scanner#eof?} but in such a way that you still get true when the next
    # token is an EOF
    #
    # @return [Boolean] whether the last token is *not* an EOF
    def next?
      @tokens.last&.type != :EOF
    end

    def eof?
      !next?
    end

    # @return [Token, nil]
    def current_token
      @tokens.last
    end

    # Run the lexer interactively, i.e, run a loop and tokenize user input.
    def self.interactive
      while line = Msh::Readline.readline("lexer> ", true)
        case line
        when "q", "quit", "exit"
          puts "goodbye! <3"
          return
        else
          begin
            puts Msh::Lexer.new(line).tokens.map(&:to_s).join("\n")
          rescue Errors::LexerError => e
            puts e.message
          end
        end
      end
    end

    # Run the lexer on a file, and print all of it's tokens.
    def self.lex_file filename
      puts new(File.read(filename)).tokens
    rescue Errors::LexerError => e
      puts e.message
    end

    # Run the lexer, either on all files passed to ARGV, or interactively, if
    # no files are supplied. Aborts program on error.
    def self.start files = ARGV
      return Lexer.interactive if files.empty?

      files.each do |file|
        raise Errors::LexerError, "#{file} is not a file!" unless File.file? file

        puts Lexer.new(File.read(file)).tokens.map(&:to_s).join("\n")
      end
    end

    private

    # Raise an error with helpful output.
    #
    # @raise [Errors::LexerError]
    def error msg = nil
      raise Errors::LexerError, "error at line #{@token.line}, " \
                                "column #{@token.column}: #{msg}"
    end

    def set_token_start
      @token.line = @scanner.line
      @token.column = @scanner.column
    end

    # nils out all of our current token's fields
    #
    # @return [Token]
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

    ## Back the lexer up one character.
    ##
    ## @return [Integer] the current position index in input
    # def backup
    #  c = @scanner.backup
    #  @token.value = @token.value[0...-1]
    #  c
    # end

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
        error "unterminated string interpolation, expected `}` to complete `{` at line #{line}, column #{col}"
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
      case @scanner.current_char
      when ">"
        advance
        @token.type = :APPEND_OUT
      when "|"
        advance
        @token.type = :NO_CLOBBER
      else
        if @scanner.current_char == "&"
          advance
          advance while DIGITS.include?(@scanner.current_char)
          @token.type = :DUP_OUT_FD
        else
          @token.type = :REDIRECT_OUT
        end
      end
    end

    # @note we've just seen a `<`
    def consume_redir_left
      case @scanner.current_char
      when "&"
        # TODO: no regex
        # if @scanner.peek(3).match? /&\d+-/
        if @scanner.peek == "&" && DIGITS.include?(@scanner.peek(3)[1..-2]) && @scanner.peek(3)[2] == "-"
          3.times { advance }
          @token.type = :MOVE
        else
          advance
          advance while DIGITS.include?(@scanner.current_char)
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
      advance until NON_WORD_CHARS.include?(@scanner.current_char)
      @token.type = :WORD
    end
  end
end
