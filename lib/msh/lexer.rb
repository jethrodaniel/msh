# frozen_string_literal: true

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
  class Lexer
    class Error < Msh::Error; end

    # We match the start of a WORD by not matching anything else, then looping
    # and collecting characters as long as we see a non-whitespace, non-special
    # character or a backslash escaped speacial character.
    #
    # TODO: there's def more of these
    #
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

    # @return [Integer]
    attr_reader :line

    # @return [Integer]
    attr_reader :column

    # @param input [String]
    def initialize input
      @scanner = StringScanner.new input
      @line = @column = 1
      @tokens = []
    end

    # @return [Boolean] are there any more tokens?
    def next?
      !@scanner.eos?
    end

    # Run the lexer on the input until we collect all the tokens.
    #
    # @return [Array<Token>] all tokens in the input
    def tokens
      tokens = []
      tokens << next_token while next?

      unless tokens.last&.type == :EOF
        @curr_token = ""
        tokens << make_token(:EOF)
      end

      tokens
    end

    # @return [Token] the next token
    # @raises [Error] if the lexer is out of input, or if the input is invalid
    def next_token
      token = nil
      @curr_token = ""

      # puts "tokens: #{@tokens.map &:to_s}"
      unless next?
        if @tokens.last.type == :EOF
          error "out of input" unless next?
        else
          @curr_token = ""
          @column += 1
          return make_token :EOF
        end
      end

      until token || !next?
        # skip comments, update line and column number on newlines
        case next_char
        when "#"
          @column += @scanner.skip /[^\n]*/
          @curr_token = ""
        when " ", "\t"
          @curr_token = ""
        when "\n"
          @line += 1
          @column = 1
          @curr_token = ""
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
        when "&"
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
        when ">"
          case next_char
          when ">"
            token = make_token :APPEND_OUT
          when "|"
            token = make_token :NO_CLOBBER
          else
            put_back_char
            token = make_token :REDIRECT_OUT
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
            put_back_char
            token = make_token :REDIRECT_IN
          end
        when "|"
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
        else
          i = 1
          # puts "peek: '#{@scanner.peek 1}'"
          until NON_WORD_CHARS.include? @scanner.peek(1)
            next_char
            i += 1
            # puts "peek: '#{@scanner.peek 1}'"
          end
          token = make_token :WORD
          # error "no matching token found"
        end
      end

      token = make_token :EOF if token.nil?

      @tokens << token

      token
    end

    private

    # Raise an error with helpful output.
    #
    # @raise [Error]
    def error msg = nil
      raise Error, "Error at line #{@line}, column #{@column - @curr_token.size}: #{msg}"
    end

    # Add a new token.
    #
    # @return [Token] the token created
    def make_token type
      Token.new :type => type,
                :value => @curr_token,
                :line => @line,
                :column => @column - @curr_token.size
    end

    # @return [String] the next character of input
    def next_char
      # puts "next char, pos: #{@scanner.pos}"
      @column += 1
      @curr_token += (c = @scanner.getch) || ""
      # puts "[#{@line}:#{@column - @curr_token.size}-#{@column - 1}]: '#{@curr_token}'"
      c
    end

    # Back the lexer up one character.
    #
    # @return [Integer] the current position index in input
    def put_back_char
      # puts "put_back_char, pos: #{@scanner.pos}"
      @column -= 1
      @curr_token = @curr_token[0..-2]
      @scanner.pos -= 1
    end

    # Run the lexer interactively, i.e, run a loop and tokenize user input.
    def self.interactive
      while line = Readline.readline("lexer> ", true)&.chomp
        case line
        when "q", "quit", "exit"
          puts "goodbye! <3"
          exit
        else
          begin
            lex = Msh::Lexer.new line
            while token = lex.next_token
              puts token
            end
          rescue Error => e
            puts e.message
          end
        end
      end
    end

    # Run the lexer on a file, and print all of it's tokens.
    def self.lex_file filename
      lex = new File.read(filename)
      while token = lex.next_token
        puts token
      end
    rescue Error => e
      puts e.message
    end

    # Run the lexer, either on all files passed to ARGV, or interactively, if
    # no files are supplied. Aborts program on error.
    def self.start args = ARGV
      return Msh::Lexer.interactive if args.size.zero?

      args.each do |file|
        abort "#{file} is not a file!" unless File.file?(file)
        lex_file file
      end
    rescue Error => e
      abort e.message
    end
  end
end
