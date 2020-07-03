# frozen_string_literal: true

require "msh/core_extensions"
require "msh/readline"
require "msh/errors"
require "msh/logger"

require "msh/parsers"
require "msh/ast"
require "msh/lexer"

module Msh
  module Parsers
    class Simple
      include Msh::Logger

      DESC = "simple parser with no backtracking"

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
        :LIT,         # echo
        :TIME,        # echo time
        :VAR,         # $USER
        :INTERP,      # echo the time is #{Time.now}
        :LAST_STATUS  # $?
      ].freeze

      attr_reader :lexer

      def initialize code
        @lexer = ::Msh::Lexer.new(code).tap(&:next_token)
      end

      delegate :current_token, :lexer
      delegate :advance,       :lexer, :via => :next_token
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
        ::Msh::AST::Node.new type, children, :line => line, :column => column
      end

      def self.skip_rule name, *types
        define_method "_skip_#{name}" do
          advance while match?(*types)
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
      end

      # @return [AST]
      def _program
        _skip_ignored

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

          consume :SEMI, :NEWLINE, "expected a `;` or a newline" unless eof?

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

        while match?(*WORDS)
          c = current_token
          case c.type
          when :LIT, :TIME
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

          advance
          break unless match? :WORD
        end

        error "expected a word" if word_pieces.empty?

        s(:WORD, *word_pieces)
      end

      # @return [AST]
      def _redirect
        r = consume(*REDIRECTS, "expected a redirection operator")
        n = r.value.match(/\A(\d+)/)&.captures&.first&.to_i

        _skip_whitespace

        case r.type
        when :DUP_OUT_FD # 2>&1
          s(:REDIRECT, n, r.type)
        else
          f = consume(*WORDS, "expected a filename to complete redirection #{r}")

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
        puts DESC
        Parsers.input_loop do |line|
          parser = new line
          p parser.parse
        rescue Errors::ParseError => e
          puts e.message
        end
      end

      def self.start *args
        Parsers.start self, *args
      end
    end
  end
end
