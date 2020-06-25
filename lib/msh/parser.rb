# frozen_string_literal: true

require "msh/readline"
require "msh/errors"
require "msh/ast"
require "msh/lexer"
require "msh/logger"

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
  # spaces -> SPACE spaces
  #         | SPACE
  #
  # _ -> spaces
  #    |
  #
  # #
  # # start of grammar
  # #
  #
  # statement -> _
  #
  # # _ if_statement
  # stat -> _ comments
  #       | _ exprs
  #       | EOF
  #
  # comments -> COMMENT NEWLINE comments
  #           | COMMENT
  #
  # exprs -> expr _ SEMI _ expr
  #        | expr _ {SEMI}
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
  # command -> cmd_part _ command
  #          | cmd_part
  #
  # cmd_part -> redirect | word | assignment
  #
  # assignment -> word _ EQ _ word
  #
  # #                 | No whitespace here
  # #                 |
  # word -> word_type  word
  #       | word_type
  #
  # # note: the lexer will never output `LIT LIT`
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
  # Note: Parse methods here use are underscore-prefixed.
  class Parser
    include Msh::Logger

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

    attr_reader :lexer

    def initialize code
      @lexer = Msh::Lexer.new(code).tap(&:next_token)
    end

    delegate :current_token, :lexer
    delegate :advance,       :lexer,         :via => :next_token
    delegate :eof?,          :lexer
    delegate :line,          :current_token
    delegate :column,        :current_token

    # @raise [Error]
    def error msg = nil
      raise Errors::ParseError, "error at line #{line}, column #{column}: #{msg}"
    end

    # @param types [Array<Symbol>]
    # @return [bool]
    def match? *types
      # log.debug { "  match? #{types} | #{current_token} =#{types.include? current_token.type}" }
      types.include? current_token.type
    end

    # @param types [Array<Symbol>]
    # @param msg [String]
    def consume *types, msg
      if match?(*types)
        t = current_token
        advance
        return t
      end

      error msg
    end

    # DSL to create an AST node, like {::AST::Sexp}, but adds line/column info.
    #
    # @param type [Symbol]
    # @param children [Array]
    # @return [Msh::AST::Node]
    def s type, *children
      Msh::AST::Node.new type, children, :line => line, :column => column
    end

    def self.skip_rule name, *types
      define_method "_skip_#{name}" do |*other_types|
        advance while match?(*types, *other_types)
      end
    end

    skip_rule :whitespace, :SPACE
    skip_rule :comments,   :COMMENT
    skip_rule :newlines,   :NEWLINE
    skip_rule :ignored,    :SPACE, :COMMENT, :NEWLINE
    skip_rule :ignored_no_newline, :SPACE, :COMMENT

    # Parse all tokens into an AST
    #
    # @return [AST]
    def parse
      _program
      # _command # frozen error?
      # _word # works
      # _redirect
    end

    # @return [AST]
    def _program
      _skip_ignored :NEWLINE

      return s(:NOOP) if eof?

      parts = []

      parts += _exprs.children until eof?

      s(:PROG, *parts)
    end

    # @return [AST] :EXPRS
    def _exprs
      exprs = []

      until eof? || match?(:SEMI, :NEWLINE)
        exprs << _expr
        _skip_ignored_no_newline

        next unless match? :SEMI, :NEWLINE

        advance

        _skip_ignored_no_newline
      end

      _skip_ignored

      s(:EXPRS, *exprs)
    end

    # @return [AST] :EXPR
    def _expr
      c = _pipeline

      _skip_ignored_no_newline

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

      while match?(*WORDS, *REDIRECTS)
        if match?(*WORDS)
          cmd_parts << _word
        elsif match?(*REDIRECTS)
          cmd_parts << _redirect
        end
        _skip_whitespace

        next unless match? :EQ

        consume :EQ, "expected an `=`"
        _skip_whitespace
        error "missing value for variable assignment" unless match?(*WORDS)
        cmd_parts << s(:ASSIGN, cmd_parts.pop, _word)
        _skip_whitespace

        break if eof? || match?(:NEWLINE)

        error "expected a word, got #{current_token}" unless match?(*WORDS, *REDIRECTS)
      end

      error "expected a word or redirect" if cmd_parts.empty?

      s(:CMD, *cmd_parts)
    end

    # @return [AST] :WORD
    def _word
      log.debug { ":#{__method__}: #{current_token} | match?(*WORDS): #{match?(*WORDS)} | match?(*REDIRECTS): #{match?(*REDIRECTS)}" }
      # log.debug { "#{__method__}: #{current_token}" }

      word_pieces = []

      if match?(*WORDS) && match?(*REDIRECTS)
        puts ">>>>>>>>>>>>>>>>>>>>>"
      end
      # somehow mruby is matching redirects **and** words..
      while match?(*WORDS)
        c = current_token
        log.debug { ":#{__method__}: #{current_token} | match?(*WORDS): #{match?(*WORDS)} | match?(*REDIRECTS): #{match?(*REDIRECTS)}" }
        # log.debug { "  2#{__method__}: #{current_token}" }
        log.debug { "  2#{__method__}: #{current_token.type.inspect} | match?(*WORDS): #{match?(*WORDS)} | match?(*REDIRECTS): #{match?(*REDIRECTS)}" }
        # next if  # why?

        case c.type
        when :WORD, :TIME
          word_pieces << s(:LIT, c.value)
        when :INTERP
          word_pieces << s(:INTERP, c.value)
        when :VAR
          word_pieces << s(:VAR, c.value)
        when :LAST_STATUS
          word_pieces << s(:LAST_STATUS, c.value)
        else
          error "expected a word type, got `#{current_token}`"
        end
        log.debug { "-> #{current_token} | match?(*REDIRECTS):#{match?(*REDIRECTS)} | match?(*WORDS): #{match?(*WORDS)} " }

        advance
        # break unless match? :WORD
        log.debug { p "-> #{current_token} | match?(*REDIRECTS):#{match?(*REDIRECTS)} | match?(*WORDS): #{match?(*WORDS)} "}
      end

      error "expected a word" if word_pieces.empty?

      s(:WORD, *word_pieces)
    end

    # @return [AST]
    def _redirect
      # r = consume(:REDIRECT_OUT, "expected a redirection operator")
      r = consume(*REDIRECTS, "expected a redirection operator")
      n = r.value.match(/\A(\d+)/)&.captures&.first&.to_i

      _skip_whitespace

      case r.type
      when :DUP_OUT_FD # 2>&1
        s(:REDIRECT, n, r.type)
      else
        # f = consume(*WORDS, "expected a filename to complete redirection #{r}")
        f = consume(:WORD, "expected a filename to complete redirection #{r}")

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
      commands = [_command]

      while match? :PIPE
        advance

        _skip_whitespace

        if match?(*WORDS, *REDIRECTS)
          commands << _command
        else
          error "expected a command after `|`"
        end
      end

      return commands.first if commands.size == 1

      s(:PIPELINE, *commands)
    end

    # Run the parser interactively, i.e, run a loop and parse user input.
    def self.interactive
      while line = Msh::Readline.readline("parser> ")
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
      return Msh::Parser.interactive if args.empty?

      args.each do |file|
        raise Errors::ParseError, "#{file} is not a file!" unless File.file?(file)

        parser = Msh::Parser.new File.read(file)
        p parser.parse
      end
    end
  end
end
