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
  #  s(:EXPR,
  #    s(:PIPELINE,
  #      s(:COMMAND,
  #        s(:WORD,
  #          s(:LITERAL, "fortune"))),
  #      s(:COMMAND,
  #        s(:WORD,
  #          s(:LITERAL, "cowsay")))))
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
  # skip_whitespace -> spaces
  #                  |
  #
  # _ -> skip_space # for convenience of notation in this BNF
  #
  # #
  # # start of grammar
  # #
  #
  # root -> _ expr
  #
  # expr -> pipeline
  #       | command
  #       |
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
  # @note Parse methods here use are underscore-prefixed.
  #
  # @todo Use fancy DSL here instead of underscore prefixing?
  #
  #   ```
  #   rule :expr do # defines a `_expr` method
  #     rules(:skip_whitespace) # calls `_skip_whitespace`
  #     ...
  #   end
  #   ```
  class Parser
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

    # DSL to create an AST node, like {AST::Sexp}, but adds line/column info.
    #
    # @param type [Symbol]
    # @param children [Array]
    # @return [Msh::AST::Node]
    def s type, *children
      Msh::AST::Node.new \
        type,
        children,
        :line => current_token.line,
        :column => current_token.column
    end

    # Parse all tokens into an AST
    #
    # @return [AST]
    def parse
      _expression
    end

    # @return [AST, nil]
    def _skip_whitespace
      advance while match? :SPACE
    end

    # @return [AST]
    def _root
      _skip_whitespace
      _expression
    end

    # @return [AST]
    def _expression
      c = _command

      return s(:EXPR, s(:PIPELINE, c, *_pipeline.children)) if match? :PIPE

      return s(:EXPR, c) if c

      s(:NOOP)
    end

    # @return [AST, nil]
    def _command
      cmd = s(:COMMAND, _command_part)

      _skip_whitespace

      return cmd if eof? || match?(:PIPE)

      c = _command

      if cmd.children.compact.empty?
        s(:COMMAND, *c.children)
      else
        s(:COMMAND, *cmd.children, *c.children)
      end
    end

    # @return [AST, nil]
    def _command_part
      return advance if match?(:REDIRECT)

      _word
    end

    # @return [AST, nil]
    def _word
      return nil unless match? *WORDS

      word_pieces = []

      c = advance

      case c.type
      when :WORD, :TIME
        word_pieces << s(:LITERAL, c.value)
      when :INTERPOLATION
        word_pieces << s(:INTERPOLATION, c.value)
      end

      return s(:WORD, *word_pieces, *_word.children) if match? *WORDS

      return nil if word_pieces.empty?

      s(:WORD, *word_pieces)
    end

    # @return [AST]
    def _pipeline
      commands = []
      while match? :PIPE
        advance
        c = _command

        if c.children.compact.empty?
          error "expected a command after `|`"
        else
          commands << c
        end
      end
      s(:PIPELINE, *commands)
    end

    # Run the parser interactively, i.e, run a loop and parse user input.
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
      index = @pos - 1
      index = 0 if index.negative?
      @tokens[index]
    end
  end
end
