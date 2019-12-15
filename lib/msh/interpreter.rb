# frozen_string_literal: true

require "English" # for $CHILD_STATUS

require "msh/lexer"
require "msh/parser"
require "msh/ast"

module Racc
  class ParseError
    def pretty_message
      "error: #{message.delete_suffix(' (error)')}"
    end
  end
end

# msh interpreter.
#
# An instance of `Msh::Interpreter` is created when msh starts up, and lives
# for the duration of the shell.
#
# Includes the `AST::Processor::Mixin` module, which defines a `process`
# method which calls any `on_TOKEN` handler methods for that node. The
# point of the module is to transform ASTs - using it as an interpreter
# is a natural consequence, but this approach can be used to write verifiers,
# etc, and compose them together.
#
# That being said, we have an `on_TOKEN` method for each of our tokens, and we
# can go ahead and interpret as we go.
#
# Our entry point is the root of the grammar, i.e the `on_PIPELINE` method.
#
module Msh
  class Interpreter
    include ::AST::Processor::Mixin

    class MissingCommandError < StandardError
      def pretty_message
        # did you mean?
        message
      end
    end

    # Run the interpreter interactively.
    #
    # This is the main point of the shell, really.
    #
    # @return [Void]
    def self.interactive # rubocop:disable Metrics/AbcSize
      interpreter = Msh::Interpreter.new

      while line = Reline.readline("interpreter> ", true)&.chomp
        case line
        when "q", "quit", "exit"
          puts "goodbye! <3"
          exit
        else
          begin
            parser = Msh::Parser.new
            nodes = parser.parse line

            interpreter.process nodes
          rescue MissingCommandError, Racc::ParseError => e
            p e.pretty_message
          rescue Msh::Lexer::ScanError => e
            p e.pretty_message(parser.lexer)
          end
        end
      end
    rescue Interrupt
      system %w[stty sane]
      system %w[tput rs1]
    end

    # Execute a command via `fork`, wait for the command to finish
    #
    # TODO: spawn, so this can be more platform-independent
    #
    # @param args [Array<String>] args to execute
    # @return [Void]
    def run *args
      unless args.all? { |a| a.is_a? String }
        abort "expected Array<String>, got `#{args.class}:#{args.inspect}`"
      end

      pid = fork do
        exec *args
      rescue Errno::ENOENT => e
        puts e.message
      end

      Process.wait pid

      $CHILD_STATUS
    end

    def on_EXPR node
      abort "EXPR must contain a single child" if node.children.size > 1
      node = node.children.first

      case node.type
      when :PIPELINE
        process node
      when :OR
        or_expr = process node

        run(*or_expr.left.words)
        run(*or_expr.right.words) unless $CHILD_STATUS.exitstatus.zero?
      when :AND
        and_expr = process node

        run(*and_expr.left.words)
        return unless $CHILD_STATUS.exitstatus.zero?

        run(*and_expr.right.words)
      when :COMMAND
        # TODO: rm hack
        if process(node).words == ["help"]
          exec %[vim ./docs/msh.txt]
        end
        run *process(node).words
      else
        abort "expected one of :PIPELINE, :AND, :OR, :COMMAND"
      end
    end

    # Modified from https://gist.github.com/JoshCheek/61769bfa05d52609e15948fabfad3381
    #
    # @param node [AST::Node] a :PIPELINE node
    # @return [AST::Node] the input node
    def on_PIPELINE node
      # Convert nodes in `Msh::AST::Command, Msh::AST::Or, etc
      pipeline = process_all node

      # Setup piped commands.
      #
      # The first and last piped commands need to inherit our stdin/out/err, and
      # should close their in/out
      pipeline = pipeline.map do |cmd|
        Msh::AST::Piped.new :command => cmd,
                            :stdin => $stdin,
                            :stdout => $stdout,
                            :stderr => $stderr,
                            :close_stdin => false,
                            :close_stdout => false
      end

      # for each piped command that isn't the first or the last, connect stdout
      # to the next command's stdin
      pipeline.each_cons(2) do |(left, right)|
        right.stdin, left.stdout = IO.pipe
        right.close_stdin = true
        left.close_stdout = true
      end

      # execute each command as a child process
      pipeline.each do |piped|
        pid = fork do
          # Subprocess sets the file descriptors and execs the command
          $stdin.reopen  piped.stdin
          $stdout.reopen piped.stdout
          $stderr.reopen piped.stderr

          command = piped.command

          if command.is_a? Msh::AST::Command
            run *command.words
          elsif command.is_a? Msh::AST::Or
            abort "unimplemented"
          elsif command.is_a? Msh::AST::And
            abort "unimplemented"
          else
            abort "shouldn't be here, ouch"
          end
        end

        # Document the pid, close the piped file descriptors, on to the next
        piped.pid = pid
        piped.stdin.close  if piped.close_stdin
        piped.stdout.close if piped.close_stdout
      end

      # Wait for the children to finish, record their exit statuses
      pipeline.each do |piped|
        Process.wait piped.pid
        piped.status = $CHILD_STATUS.exitstatus
      end

      # p pipeline.last.status
    end

    # @param node [AST::Node] an :OR or :AND node
    # @return [Msh::AST::AndOr]
    def process_conditional node
      left, right = *process_all(node)

      case node.type
      when :OR
        Msh::AST::Or.new :left => left, :right => right
      when :AND
        Msh::AST::And.new :left => left, :right => right
      else
        abort "unknown AST node #{node.type}, expected :OR or :AND"
      end
    end
    alias on_OR  process_conditional
    alias on_AND process_conditional

    # @param node [AST::Node] a :COMMAND node
    # @return [Msh::Command]
    def on_COMMAND node
      Msh::AST::Command.from_node node
    end
  end
end
