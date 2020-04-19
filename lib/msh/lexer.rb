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
      @line = @column = 1
      @tokens = []
    end

    # Run the lexer on the input until we collect all the tokens.
    #
    # @return [Array<Token>] all tokens in the input
    def tokens
      next_token until @tokens.last&.type == :EOF
      # next_token until eof?
      # make_token(:EOF) unless @tokens.last&.type == :EOF
      @tokens
    end

    # @return [Token] the next token
    # @raises [Error] if the lexer is out of input, or if the input is invalid
    def next_token
      @matched = ""

      if eof?
        if @tokens.last&.type == :EOF
          error "out of input"
        else
          t = make_token :EOF
          @tokens << t
          return t
        end
      end

      token = nil

      until token || eof?
        case next_char
        when "#" # could be a comment, or start of string interpolation
          case next_char
          when "{" # start of string interpolation
            @matched = ""
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
              @matched = ""
              error <<~ERR
                unterminated string interpolation, expected `}` to complete `\#{` at line #{line}, column #{col}
              ERR
            end

            @matched = @matched[0...-1] # discard the `}`
            @column -= 1 # hack
            token = make_token :INTERPOLATION
            @column += 1 # hack
          else # a comment
            @column -= 1 # subtract one for the `{`
            @column += @scanner.skip(/[^\n]*/)
            @matched = ""
            require 'pry';require 'pry-byebug';binding.pry;nil
            puts

          end
        when " ", "\t" # skip whitespace
          @matched = ""
        when "\n" # newlines
          @line += 1
          @column = 1
          @matched = ""
        when ";"
          token = make_token :SEMI
        when "t"
          case next_char
          when "i"
            case next_char
            when "m"
              case next_char
              when "e"
                # TODO: `time -p` here?
                token = make_token :TIME
              end
            end
          end
        when "{"
          token = make_token :LEFT_BRACE
        when "}"
          token = make_token :RIGHT_BRACE
        when "("
          token = make_token :LEFT_PAREN
        when ")"
          token = make_token :RIGHT_PAREN
        when "!"
          token = make_token :BANG
        when "&" # could be &, &&, &>, or &>>
          case next_char
          when "&"
            token = make_token :AND
          when ">"
            case next_char
            when ">"
              token = make_token :AND_D_REDIRECT_RIGHT
            else
              put_back_char
              token = make_token :AND_REDIRECT_RIGHT
            end
          else
            token = make_token :BG
          end
        when ">" # could be >, >>, or >|
          case next_char
          when ">"
            token = make_token :APPEND_OUT
          when "|"
            token = make_token :NO_CLOBBER
          else
            put_back_char
            token = make_token :REDIRECT_OUT
          end
        when "<" # could be <, <&n-, <&n, or <>
          case next_char
          when "&"
            case next_char
            when "1".."9"
              case next_char
              when "-"
                token = make_token :MOVE
              end
            else
              put_back_char
              token = make_token :DUP
            end
          when ">"
            token = make_token :OPEN_RW
          else
            put_back_char
            token = make_token :REDIRECT_IN
          end
        when "|" # could be |, ||, or |&
          case next_char
          when "|"
            token = make_token :OR
          when "&"
            token = make_token :PIPE_AND
          else
            put_back_char
            token = make_token :PIPE
          end
        when "1".."9" # TODO: support more than 9 file descriptors
          case next_char
          when ">"
            case next_char
            when ">"
              token = make_token :APPEND_OUT
            when "|"
              token = make_token :NO_CLOBBER
            else
              put_back_char
              token = make_token :REDIRECT_OUT
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
                  token = make_token :MOVE
                end
              else
                put_back_char
                token = make_token :DUP
              end

            when ">"
              token = make_token :OPEN_RW
            else
              # TODO
              # open_rw n<>
              # << here strings?
              # n<&
              # put_back_char
              token = make_token :REDIRECT_IN
            end
          end
        else # must be a word, or the end of input
          next_char until NON_WORD_CHARS.include?(@scanner.peek(1))

          if @matched == ""
            token = make_token :EOF
          else
            token = make_token :WORD
          end
        end
      end

      token = make_token :EOF if token.nil?

      @tokens << token

      token
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
      raise Error, "error at line #{@line}, column #{@column - @matched.size}: #{msg}"
    end

    # @return [Token] a new token
    def make_token type
      Token.new :type => type,
                :value => @matched,
                :line => @line,
                :column => @column - @matched.size
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
      @matched += c unless c.nil?
      c
    end

    # Back the lexer up one character.
    #
    # @return [Integer] the current position index in input
    def put_back_char
      @column -= 1
      @matched = @matched[0...-1]
      @scanner.pos -= 1
    end
  end
end
