# frozen_string_literal: true

module Msh
  # This AST class contains more specialized AST command representations, like
  #
  #     a = Command.new :words => %w[echo hi]
  #     b = Command.new :words => %w[cowsay]
  #
  #     cond = And.new :left => a, :right => b
  #
  #     p = Pipeline.new :piped => [cond, b]
  #
  module AST
    class Pipeline
      attr_reader :piped

      # @param piped [Array<Msh::AST::AndOr, Msh::AST::Command]
      def initialize piped:
        raise "piped must be `Piped`s" unless piped.all? { |p| p.is_a? Piped }

        @piped = piped
      end

      def == other
        @piped == other.piped
      end
    end

    class Piped
      attr_accessor \
        :command,      # the source AST command
        :stdin,        # in for this command
        :stdout,       # out for this command
        :stderr,       # error for this command
        :close_stdin,  # close stdin after running?
        :close_stdout, # close stdout after running?
        :pid,          # the program's pid (or the last of a command)
        :status        # the exit code of the last program

      def initialize command:, stdin:, stdout:, stderr:, close_stdin:, close_stdout:
        unless command.is_a?(AndOr) || command.is_a?(Command)
          raise <<~MSG
            piped must be `AST::AndOr` or `AST::Command`, got `#{command.type}`
          MSG
        end

        unless [stdin, stdout, stderr].all? { |io| io.is_a? IO }
          raise "stdin/out/err must be `IO` instances"
        end

        unless [close_stdin, close_stdout].all? { |b| [true, false].include? b }
          raise "close_stdin/out must be booleans"
        end

        @command = command
        @stdin = stdin
        @stdout = stdout
        @stderr = stderr
        @close_stdin = close_stdin
        @close_stdout = close_stdout
      end

      def == other
        @command == other.command &&
          @stdin == other.stdin &&
          @stdout == other.stdout &&
          @stderr == other.stderr &&
          @close_stdin == other.close_stdin &&
          @close_stdout == other.close_stdout
      end
    end

    class Command
      attr_reader :words

      def initialize words:
        @words = words
      end

      def == other
        other.words == @words
      end

      # @param node [AST::Node]
      # @return [Command]
      def self.from_node node
        words = node.children.map do |word|
          if word.children.size > 1
            raise "expected only 1 child, got #{command.children.inspect}"
          end

          word.children.first
        end

        new :words => words
      end
    end

    class AndOr
      attr_reader :left, :right

      # @param left [Command]
      # @param right [Command]
      def initialize left:, right:
        unless [left, right].all? { |p| p.is_a? Command }
          raise <<~MSG
            :left and :right must be `AST::Command`s, got `#{left}`, `#{right}`
          MSG
        end

        @left = left
        @right = right
      end

      def == other
        [other.left, other.right] == [@left, @right]
      end
    end

    And = AndOr
    Or  = AndOr
  end
end
