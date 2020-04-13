# frozen_string_literal: true

require "readline"

require "ast"
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
  # expr -> pipeline
  #
  # pipeline -> pipeline cmd
  #           | cmd PIPE cmd
  #           | cmd
  #
  # cmd -> cmd WORD
  #      | WORD
  # ```
  #
  # This particular parser is a recursive descent parser, which starts
  # matching at the root of the grammar, then dispatches to methods for
  # each production.
  class Parser
    # AST::Sexp allows us to easily create AST nodes, using s-expression syntax,
    # i.e, `s(:TOKEN)`, or `s(:TOKEN, [children...])`.
    include ::AST::Sexp

    class Error < Msh::Error; end

    REDIRECT_OPS = %i[
      REDIRECT_LEFT
      REDIRECT_RIGHT
      D_REDIRECT_LEFT
      D_REDIRECT_RIGHT
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

    # NOTE: Root of the grammar.
    #
    # @return [AST]
    def expression
      s(:EXPR, pipeline)
    end

    # @return [AST]
    def pipeline
      prefix = if match? :TIME
                 p = s(:TIME)
                 advance
                 p
               end

      commands = []
      commands << (c = command)

      while match? :PIPE
        advance # skip pipe

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
          c
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

      words << s(:WORD, advance.value) while match? :WORD, :TIME

      suffix = redirection

      if prefix.size.zero? && words.size.zero? && suffix.size.zero?
        error "expected a command, got #{current_token}"
      elsif prefix.size.zero? && suffix.size.zero?
        s(:COMMAND, *words)
      else
        s(:COMMAND, prefix, *words, suffix)
      end
    end

    # @return [AST]
    def redirection
      redirections = []

      io_num = io_number

      while match? REDIRECT_OPS
        redirect = advance

        error "expected a filename" unless match(:WORD)

        filename = advance

        redirections << if io_num
                          s(:REDIRECTION, io_num, redirect, filename)
                        else
                          s(:REDIRECTION, redirect, filename)
                        end
      end

      redirections
    end

    # @return [AST]
    def io_number
      advance if match? :IO_NUMBER
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
  end
end
