# frozen_string_literal: true

require "reline"

require "msh/errors"
require "msh/ast"
require "msh/lexer"

module Msh
  # The parser converts a series of tokens into an abstract syntax tree (AST).
  #
  # @example
  #     parser = Msh::Parser.new "fortune | cowsay"
  #     ast = \
  #       s(:PROG,
  #         s(:EXPR,
  #           s(:PIPELINE,
  #             s(:CMD,
  #               s(:WORD,
  #                 s(:LIT, "fortune"))),
  #             s(:CMD,
  #               s(:WORD,
  #                 s(:LIT, "cowsay"))))))
  #     parser.parse == ast #=> true
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
  # cmd_part -> redirect | word | assignment
  #
  # assignment -> word _ EQ _ word
  #
  # # Note: `WORD`s from the lexer are "built" up into AST WORDs - consider
  # #
  # #    echo a#{b}c$(d)e$USER
  # #
  # # Which yields
  # #
  # #    s(:WORD,
  # #      s(:LIT, "a"),
  # #      s(:INTERP, "#{b}"),
  # #      s(:LIT, "c"),
  # #      s(:SUB, "d"),
  # #      s(:LIT, "e"),
  # #      s(:VAR, "$USER"))
  # #
  # #                 | No whitespace here
  # #                 |
  # word -> word_type  word
  #       | word_type
  #
  # # The lexer will never output `LIT LIT`
  # word_type -> LIT      # echo
  #            | INTERP   # #{Time.now}
  #            | SUB      # $(date)
  #            | VAR      # $USER
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
      :WORD,        # echo
      :TIME,        # echo time
      :VAR,         # $USER
      :INTERP,      # echo the time is #{Time.now}
      :LAST_STATUS  # $?
    ].freeze

    def initialize code
      @pos = 0
      @lexer = Msh::Lexer.new code
      @tokens = [@lexer.next_token]
    end

    # @return [Integer]
    def line
      peek.line
    end

    # @return [Integer]
    def column
      peek.column
    end

    # DSL to create an AST node, like {::AST::Sexp}, but adds line/column info.
    #
    # @param type [Symbol]
    # @param children [Array]
    # @return [Msh::AST::Node]
    def s type, *children
      Msh::AST::Node.new \
        type,
        children,
        :line => peek.line,
        :column => peek.column
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

    def _skip_comments
      advance while match? :COMMENT, :NEWLINE
    end

    # @return [AST]
    def _program
      _skip_whitespace

      return s(:NOOP) if eof?

      exprs = []

      until eof?
        exprs << _expr
        _skip_whitespace
        _skip_comments

        next unless match? :SEMI, :NEWLINE

        advance
        _skip_whitespace
        _skip_comments
        next
      end

      s(:PROG, *exprs)
    end

    # @return [AST] :EXPR
    def _expr
      c = _pipeline

      _skip_whitespace

      if match? :AND, :OR
        op = consume :AND, :OR, "expected an `&&` or an `||`"
        _skip_whitespace
        right = _pipeline
        return s(:EXPR, s(op.type, c, right))
      end

      return s(:EXPR, s(:PIPELINE, c, *_pipeline.children)) if match? :PIPE

      s(:EXPR, c)
    end

    # @return [AST] :ASSIGN, :WORD
    def _command
      cmd_parts = []

      while match? *WORDS, *REDIRECTS
        if match? *WORDS
          cmd_parts << _word
        elsif match? *REDIRECTS
          cmd_parts << _redirect
        end
        _skip_whitespace

        next unless match?(:EQ)

        consume :EQ, "expected an `=`"
        _skip_whitespace
        error "missing value for variable assignment" unless match? *WORDS
        cmd_parts << s(:ASSIGN, cmd_parts.pop, _word)
        _skip_whitespace

        break if eof? || match?(:NEWLINE)

        error "expected a word, got #{peek}" unless match? *WORDS, *REDIRECTS
      end

      error "expected a word or redirect" if cmd_parts.size.zero?

      s(:CMD, *cmd_parts)
    end

    # @return [AST] :WORD
    def _word
      word_pieces = []

      while match? *WORDS
        c = peek

        case c.type
        when :WORD, :TIME
          word_pieces << s(:LIT, c.value)
        when :INTERP
          word_pieces << s(:INTERP, c.value)
        when :VAR
          word_pieces << s(:VAR, c.value)
        when :LAST_STATUS
          word_pieces << s(:LAST_STATUS, c.value)
        end

        advance
      end

      error "expected a word" if word_pieces.size.zero?

      s(:WORD, *word_pieces)
    end

    # @return [AST]
    def _redirect
      r = consume *REDIRECTS, "expected a redirection operator"
      n = r.value.match(/\A(\d+)/)&.captures&.first&.to_i

      _skip_whitespace

      case r.type
      when :DUP_OUT_FD # 2>&1
        s(:REDIRECT, n, r.type)
      else
        f = consume *WORDS, "expected a filename to complete redirection #{r}"

        case r.type
        when :REDIRECT_OUT, :APPEND_OUT, :AND_REDIRECT_RIGHT
          n ||= 1
        when :REDIRECT_IN
          n ||= 0
        else
          error "unknown redirection type `#{r}`"
        end

        s(:REDIRECT, s(r.type, n, f.value))
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
      while line = Reline.readline("parser> ", true)&.chomp
        case line
        when "q", "quit", "exit"
          puts "goodbye! <3"
          return
        else
          begin
            parser = Msh::Parser.new line
            p parser.parse
          rescue Errors::ParseError => e
            puts e.message
          end
        end
      end
    end

    # Parse each file passed as input (if any), or run interactively
    def self.start args = ARGV
      return Msh::Parser.interactive if args.size.zero?

      args.each do |file|
        unless File.file?(file)
          raise Errors::ParseError, "#{file} is not a file!"
        end

        parser = Msh::Parser.new File.read(file)
        p parser.parse
      end
    end

    private

    # Raise an error with helpful output.
    #
    # @raise [Error]
    def error msg = nil
      line = peek.line
      col = peek.column
      raise Errors::ParseError, "error at line #{line}, column #{col}: #{msg}"
    end

    # @param types [Symbol...]
    # @return [bool]
    def match? *types
      types.any? { |t| peek.type == t }
    end

    # @return [Token, nil]
    def advance
      return if eof?

      @pos += 1
      @tokens << @lexer.next_token
      prev
    end

    # @return [bool]
    def eof?
      peek.type == :EOF
    end

    # @param nth [Integer]
    # @return [Token]
    def peek nth = 0
      return @tokens[@pos + nth] if @tokens[@pos + nth]

      peek nth - 1
      @tokens[@pos + nth] = @lexer.next_token
    end
    alias current_token peek

    # @return [Token]
    def prev
      index = @pos - 1
      index = 0 if index.negative?
      @tokens[index]
    end

    # @param types [...Symbol]
    # @param msg [String]
    def consume *types, msg
      if match? *types
        c = peek.dup
        advance
        c
      else
        error msg
      end
    end
  end
end
