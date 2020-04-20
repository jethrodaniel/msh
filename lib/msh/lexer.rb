# frozen_string_literal: true

require "readline"
require "strscan"

require "msh/error"
require "msh/token"

module Msh
  # The lexer breaks down input text into a series of tokens.
  #
  # ```
  # lex = Lexer.new "fortune | cowsay\n"
  # lex.next_token #=> [1:1-7][WORD, 'fortune']
  # lex.next_token #=> [1:9-9][PIPE, '|']
  # lex.next_token #=> [1:11-16][WORD, 'cowsay']
  # lex.next_token #=> [2:1-1][EOF, '']
  # lex.next_token #-=> Lexer::Error, "out of input"
  # ```
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
  class Lexer
    class Error < Msh::Error; end

    # TODO: there's def more of these
    NON_WORD_CHARS = [
      "",
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
      @scanner = StringScanner.new input
      @line    = 1
      @column  = 1
      @tokens  = []
      @token   = Token.new
    end

    # Run the lexer on the input until we collect all the tokens.
    #
    # @return [Array<Token>] all tokens in the input
    def tokens
      next_token until @token.type == :EOF
      # next_token until eof?
      # make_token(:EOF) unless @tokens.last&.type == :EOF
      @tokens
    end

    # @return [Token] the next token
    # @raises [Error] if the lexer is out of input, or if the input is invalid
    def next_token
      reset_token

      if eof?
        if @tokens.last&.type == :EOF
          error "out of input"
        else
          set_token_start
          @token.type = :EOF
          return add_token
        end
      end

      set_token_start

      until eof?
        case next_char
        when "#" # could be a comment, or start of string interpolation
          case next_char
          when "{" # start of string interpolation
            reset_and_set_start

            line = @line
            col = @column - 2
            l_brace_stack = []

            while c = next_char # loop until closing `}`
              break if c.nil? || eof?

              case c
              when "{"
                l_brace_stack << c
              when "}"
                if l_brace_stack.empty? # end of interpolation
                  break
                else
                  l_brace_stack.pop
                end
              end
            end

            if l_brace_stack.size.positive? # || c.nil? || eof?
              error <<~ERR
                unterminated string interpolation, expected `}` to complete `\#{` at line #{line}, column #{col}
              ERR
            end

            @token.value = @token.value[0...-1] # discard the `}`
            @column -= 1 # hack
            @token.type = :INTERPOLATION
            @column += 1 # hack
            return add_token
          else # a comment
            @column -= 1 # subtract one for the `{`
            @column += @scanner.skip(/[^\n]*/)
            @token.value = ""
          end
        when " ", "\t" # skip whitespace
          reset_token
          set_token_start
          next
        when "\n" # newlines
          @line += 1
          @column = 1
          next
        when ";"
          @token.type = :SEMI
        when "t"
          case next_char
          when "i"
            case next_char
            when "m"
              case next_char
              when "e"
                # TODO: `time -p` here?
                @token.type = :TIME
              end
            end
          end
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
        when "&" # could be &, &&, &>, or &>>
          case next_char
          when "&"
            @token.type = :AND
          when ">"
            case next_char
            when ">"
              @token.type = :AND_D_REDIRECT_RIGHT
            else
              put_back_char
              @token.type = :AND_REDIRECT_RIGHT
            end
          else
            @token.type = :BG
          end
        when ">" # could be >, >>, or >|
          case next_char
          when ">"
            @token.type = :APPEND_OUT
          when "|"
            @token.type = :NO_CLOBBER
          else
            put_back_char
            @token.type = :REDIRECT_OUT
          end
        when "<" # could be <, <&n-, <&n, or <>
          case next_char
          when "&"
            case next_char
            when "1".."9"
              case next_char
              when "-"
                @token.type = :MOVE
              end
            else
              put_back_char
              @token.type = :DUP
            end
          when ">"
            @token.type = :OPEN_RW
          else
            put_back_char
            @token.type = :REDIRECT_IN
          end
        when "|" # could be |, ||, or |&
          case next_char
          when "|"
            @token.type = :OR
          when "&"
            @token.type = :PIPE_AND
          else
            put_back_char
            @token.type = :PIPE
          end
        when "1".."9" # TODO: support more than 9 file descriptors
          case next_char
          when ">"
            case next_char
            when ">"
              @token.type = :APPEND_OUT
            when "|"
              @token.type = :NO_CLOBBER
            else
              put_back_char
              @token.type = :REDIRECT_OUT
              # else
              #   word can start with a number, why not?
            end
          when "<"
            case next_char
            when "&"
              case next_char
              when "1".."9"
                case next_char
                when "-"
                  @token.type = :MOVE
                end
              else
                put_back_char
                @token.type = :DUP
              end

            when ">"
              @token.type = :OPEN_RW
            else
              # TODO
              # open_rw n<>
              # << here strings?
              # n<&
              # put_back_char
              @token.type = :REDIRECT_IN
            end
          end
        else # must be a word, or the end of input
          next_char until NON_WORD_CHARS.include?(@scanner.peek(1))

          if @token.value == ""
            @token.type = :EOF
            return add_token
          else
            @token.type = :WORD
            return add_token
          end
        end
      end
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

    # @return [Token, nil]
    def add_token
      @tokens << @token.dup
      current_token
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
      raise Error, "error at line #{@line}, column #{@column - @token.value.size}: #{msg}"
    end

    # @return [Token] a new token
    def make_token type
      Token.new :type => type,
                :value => @token.value,
                :line => @line,
                :column => @column - @token.value.size
    end

    def set_token_start
      @token.line = @line
      @token.column = @column
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

    # @return [Boolean] has the scanner reached the end of input?
    def eof?
      @scanner.eos?
    end

    # @return [String] the current character of input
    def current_char
      @scanner.string[@scanner.pos]
    end

    # @return [String] the next character of input
    def next_char
      c = @scanner.getch
      @column += 1
      @token.value += c unless c.nil?
      c
    end

    # Back the lexer up one character.
    #
    # @return [Integer] the current position index in input
    def put_back_char
      @column -= 1
      @token.value = @token.value[0...-1]
      @scanner.pos -= 1
    end
  end
end
