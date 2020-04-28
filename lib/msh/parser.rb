# frozen_string_literal: true

require "readline"

require "msh/ast"
require "msh/error"
require "msh/lexer"

module Msh
  # The parser converts a series of tokens into an abstract syntax tree (AST).
  #
  # ```
  # lexer = Lexer.new "fortune | cowsay\n"
  # parser = Parser.new lexer.tokens
  # parser.parse
  # #=>
  #   s(:EXPR,
  #    s(:PIPELINE,
  #      s(:COMMAND,
  #        s(:WORD, "fortune")),
  #      s(:COMMAND,
  #        s(:WORD, "cowsay"))))
  # ```
  #
  # The grammar parsed is as follows
  #
  # ```
  # # basic BNF-like notation with comments. Tokens are UPCASE.
  # #
  # # # comments after `#`
  # # rule -> production_1 TOKEN
  # #       | production_2
  # #       | # empty
  #
  # #
  # # basics
  # #
  #
  # digits -> digit digits
  #         | digit
  #
  # digit -> 0
  #        | 1
  #        | 2
  #        | 3
  #        | 4
  #        | 5
  #        | 6
  #        | 7
  #        | 8
  #        | 9
  #
  # spaces -> SPACE spaces
  #         |
  #
  # skip_space -> spaces
  #             |
  #
  # _ -> skip_space # for convenience of notation
  #
  # #
  # # start of grammar
  # #
  #
  # root -> _ expr
  #
  # expr -> pipeline
  #       | command
  #       | EOF
  #
  # pipeline_prefix -> time
  #                  |
  #
  # pipeline -> command _ PIPE _ pipeline_prefix _ pipeline_cmd
  #           | command
  #
  # command_part -> redirect
  #               | word
  #
  # command -> command_part _ command
  #          | command_part
  #
  # # Note: `word`s here are actually "built" up into WORDS - consider
  # #
  # #    echo a#{b}c$(d)e
  # #
  # # Which yields
  # #
  # #    s(:WORD,
  # #      s(:LITERAL, "a"),
  # #      s(:INTERPOLATION, "#{b}"),
  # #      s(:LITERAL, "c"),
  # #      s(:SUBSTITUTION, "d"),
  # #      s(:LITERAL, "e"))
  # #
  # #           | No whitespace here
  # #           |
  # word -> WORD word
  #       | WORD
  #
  # redirect -> REDIRECT_OUT          # [n]>
  #           | REDIRECT_IN           # [n]<
  #           | APPEND_OUT            # [n]>>
  #           | AND_REDIRECT_RIGHT    # [n]&>
  #           | AND_D_REDIRECT_RIGHT  # [n]&>>
  #           | DUP_OUT_FD            # [n]>&n
  #           | DUP_IN_FD             # [n]<&n
  #           | NO_CLOBBER            # [n]>|
  # ```
  #
  # This implementation is a recursive descent parser, which starts matching at
  # the root of the grammar, then dispatches to methods for each production.
  # More specifically, there is a parse method for each non-terminal symbol,
  # and terminal symbols on the right-hand side of a rule consume themselves
  # from the input.
  #
  # Each parsing method returns an AST - we collect these as we traverse the
  # tokens, to build up the final AST.
  #
  # Note that an AST is generated, _not_ a parse tree.
  #
  class Parser
    include Msh::AST::Sexp

    class Error < Msh::Error; end

    REDIRECT_OPS = [
      :REDIRECT_OUT,         # [n]>
      :REDIRECT_IN,          # [n]<
      :APPEND_OUT,           # [n]>>
      :AND_REDIRECT_RIGHT,   # [n]&>
      :AND_D_REDIRECT_RIGHT, # [n]&>>
      :DUP_OUT_FD,           # [n]>&n
      :DUP_IN_FD,            # [n]<&n
      :NO_CLOBBER            # [n]>|
    ].freeze

    WORDS = [
      :WORD,         # echo
      :TIME,         # echo time
      :INTERPOLATION # echo the time is #{Time.now}
    ].freeze

    # @return [Array<Token>]
    attr_reader :tokens

    def initialize tokens
      @pos = 0
      @tokens = tokens
    end

    # @return [Integer]
    def line
      current_token.line
    end

    # @return [Integer]
    def column
      current_token.column
    end

    # Parse all tokens into an AST
    #
    # @return [AST]
    def parse
      expression
    end

    # @note Root of the grammar.
    #
    # @return [AST]
    def expression
      skip_whitespace

      return s(:NOOP) if eof?

      s(:EXPR, pipeline_or_command)
    end

    # @return [AST]
    def pipeline_or_command
      prefix = if match? :TIME
                 p = s(:TIME)
                 advance
                 p
               end

      skip_whitespace

      commands = []
      commands << (c = command)

      while match? :PIPE
        advance # skip pipe
        skip_whitespace

        if match? :WORD
          commands << command
        else
          error "expected a command after '|'"
        end
      end

      case commands.size
      when 0
        error "expected a command"
      when 1
        if prefix
          s(:PIPELINE, prefix, *commands)
        else
          c # return :COMMAND
        end
      else
        if prefix
          s(:PIPELINE, prefix, *commands)
        else
          s(:PIPELINE, *commands)
        end
      end
    end

    # @return [AST]
    def command
      words = []

      prefix = redirection

      while match? :WORD, :TIME, :INTERPOLATION, :NEWLINE, :SPACE
        case peek.type
        when :INTERPOLATION
          # if words.last&.type == :WORD
          # puts "word started"
          # words << s(:WORD, advance.value)
          # else
          # puts "not word started"
          words << s(:INTERPOLATION, advance.value)
          # end
        when :WORD, :TIME
          # puts "word"
          words << s(:WORD, advance.value)
        else
          advance
        end
      end

      suffix = redirection

      if prefix.size.zero? && words.size.zero? && suffix.size.zero?
        error "expected a command, got #{current_token.value.inspect}"
      elsif prefix.size.zero? && suffix.size.zero?
        s(:COMMAND, *words)
      else
        s(:COMMAND, *prefix, *words, *suffix)
      end
    end

    # @return [AST]
    def redirection
      redirections = []

      io_num = io_number

      while match? *REDIRECT_OPS
        redirect = advance
        skip_whitespace

        io_num = current_token.value.match(/\d+/).to_a.first

        if io_num.nil?
          io_num = case redirect.type
                   when :REDIRECT_OUT then 1
                   when :REDIRECT_IN then 0
                     # when :AND_REDIRECT_RIGHT then 0
                   end
        end

        error "expected a filename, got #{current_token}" unless match?(:WORD)

        filename = advance.value

        redirect = redirect.value.delete_prefix(io_num.to_s)
        redirections << s(:REDIRECTION, io_num, redirect, filename)
      end

      redirections
    end

    # @return [AST]
    def io_number
      advance if match? :IO_NUMBER
    end

    # Run the parser interactively, i.e, run a loop and parser user input.
    def self.interactive
      while line = Readline.readline("parser> ", true)&.chomp
        case line
        when "q", "quit", "exit"
          puts "goodbye! <3"
          return
        else
          begin
            lexer = Msh::Lexer.new line
            parser = Msh::Parser.new lexer.tokens
            p parser.parse
          rescue Error => e
            puts e.message
          end
        end
      end
    end

    # Parse each file passed as input (if any), or run interactively
    def self.start args = ARGV
      return Msh::Parser.interactive if args.size.zero?

      args.each do |file|
        raise Error, "#{file} is not a file!" unless File.file?(file)

        lexer = Msh::Lexer.new File.read(file)
        parser = Msh::Parser.new lexer.tokens
        p parser.parse
      end
    end

    private

    # Raise an error with helpful output.
    #
    # @raise [Error]
    def error msg = nil
      line = current_token.line
      col = current_token.column
      raise Error, "error at line #{line}, column #{col}: #{msg}"
    end

    # @param types [Symbol...]
    # @return [bool]
    def match? *types
      types.any? { |t| peek.type == t }
    end

    # @return [Token]
    def current_token
      @tokens[@pos]
    end

    # @return [Token, nil]
    def advance
      return if eof?

      @pos += 1
      prev
    end

    # @return [bool]
    def eof?
      peek.type == :EOF
    end

    # @return [Token]
    def peek
      @tokens[@pos]
    end

    # @return [Token]
    def prev
      @tokens[@pos - 1]
    end

    def skip_whitespace
      advance while match? :SPACE
    end
  end
end
