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
  #      s(:CMD,
  #        s(:WORD,
  #          s(:LIT, "fortune"))),
  #      s(:CMD,
  #        s(:WORD,
  #          s(:LIT, "cowsay")))))
  # ```
  #
  # The grammar parsed is as follows
  #
  # ```
  # # basic EBNF-like notation with comments. Tokens are UPCASE.
  # #
  # # # comments after `#`
  # # rule -> production_1 TOKEN
  # #       | production_2
  # #       | {a} # zero or more times
  # #       | {a}+ # one or more times
  # #       | # empty
  # #
  # # {...} leads to while-loops
  # # .. | .. leads to if-else/case
  #
  # #
  # # basics
  # #
  #
  # spaces -> {SPACE}
  #
  # _ -> spaces # for convenience of notation in this BNF
  #
  # #
  # # start of grammar
  # #
  #
  # program -> _ expr _ SEMI _ expr
  #          | _ expr _ {SEMI}
  #          | EOF
  #
  # expr -> and_or
  #       | pipeline
  #
  # and_or -> pipeline AND pipeline
  #         | pipeline OR pipeline
  #
  # pipeline -> command _ PIPE _ pipeline
  #           | command
  #
  # command -> cmd_part _ command # {cmd_part}+, but skipping whitespace
  #          | cmd_part
  #
  # cmd_part -> redirect | word
  #
  # # Note: `word`s here are actually "built" up into WORDS - consider
  # #
  # #    echo a#{b}c$(d)e
  # #
  # # Which yields
  # #
  # #    s(:WORD,
  # #      s(:LIT, "a"),
  # #      s(:INTERP, "#{b}"),
  # #      s(:LIT, "c"),
  # #      s(:SUBSTITUTION, "d"),
  # #      s(:LIT, "e"))
  # #
  # #           | No whitespace here
  # #           |
  # word -> WORD word  # equivalent to {WORD}+
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

    REDIRECTS = [
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
      :INTERP # echo the time is #{Time.now}
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
      _program
    end

    # @return [AST, nil]
    def _skip_whitespace
      advance while match? :SPACE
    end

    # @return [AST]
    def _program
      _skip_whitespace

      return s(:NOOP) if eof?

      exprs = []

      until eof?
        exprs << _expr
        _skip_whitespace
        if match? :SEMI
          advance
          _skip_whitespace
          next
        end
        _skip_whitespace
      end

      s(:PROG, *exprs)
    end

    # @return [AST]
    def _expr
      c = _pipeline

      _skip_whitespace

      if match? :AND, :OR
        op = advance
        _skip_whitespace
        right = _pipeline
        return s(:EXPR, s(op.type, c, right))
      end

      return s(:EXPR, s(:PIPELINE, c, *_pipeline.children)) if match? :PIPE

      s(:EXPR, c)
    end

    # @return [AST]
    def _and_or
      cmds = []

      c = advance

      _skip_whitespace

      case c.type
      when :AND
        return s(:AND, _pipeline, _pipeline)
      when :OR
        return s(:OR, _pipeline, _pipeline)
      end

      _skip_whitespace
    end

    # @return [AST]
    def _command
      cmd_parts = []

      while match? *WORDS, *REDIRECTS
        cmd_parts << _word if match? *WORDS
        _skip_whitespace
        cmd_parts << _redirect if match? *REDIRECTS
        _skip_whitespace
      end

      s(:CMD, *cmd_parts)
    end

    # @return [AST]
    def _word
      word_pieces = []

      while match? *WORDS
        c = advance

        case c.type
        when :WORD, :TIME
          word_pieces << s(:LIT, c.value)
        when :INTERP
          word_pieces << s(:INTERP, c.value)
        end
      end

      s(:WORD, *word_pieces)
    end

    # @return [AST]
    def _redirect
      r = consume *REDIRECTS, "expected a redirection operator"
      n = r.value.match(/\A(\d+)/)&.captures&.first&.to_i || 1

      _skip_whitespace

      case r.type
      when :DUP_OUT_FD # 2>&1
        s(:REDIRECT, n, r.type)
      else
        f = consume *WORDS, "expected a filename to complete redirection #{r}"
        s(:REDIRECT, n, r.type, f.value)
      end
    end

    # @return [AST] type :PIPELINE or :CMD
    def _pipeline
      commands = []

      while match? :PIPE
        advance

        _skip_whitespace

        if match? *WORDS, *REDIRECTS
          commands << _command
        else
          error "expected a command after `|`"
        end
      end

      return _command if commands.size.zero?

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

    # @param type [...Symbol]
    # @param msg [String]
    def consume *types, msg
      if match? *types
        advance
      else
        error msg
      end
    end
  end
end
