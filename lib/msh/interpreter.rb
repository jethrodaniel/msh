# frozen_string_literal: true

require "English"
require "ast"
require "paint"

require "msh/logger"
require "msh/env"
require "msh/documentation"
require "msh/ast"
require "msh/lexer"
require "msh/parser"

module Msh
  # The interpreter executes an AST.
  #
  # It also maintains its own environment, and has access to a user's config.
  #
  # ```
  # lex = Lexer.new "fortune | cowsay\n"
  # parser = Parser.new lex.tokens
  # interpreter = Interpreter.new parser.parse lex.tokens
  # ```
  class Interpreter
    include Msh::Logger

    # `AST::Processor::Mixin` defines the following for us
    #
    # ```
    #  def process(node)      #=> calls method `on_TOKEN` for node type TOKEN
    #  def process_all(nodes) #=> nodes.map { |n| process n }
    # ```
    #
    # Each `on_TOKEN` type is responsible for handling its children. This
    # allows `process` to recursively traverse the AST.
    include ::AST::Processor::Mixin

    def initialize
      log.debug { "initialized new interpreter" }
      @env = Env.new
    end

    def prompt
      @env.prompt
    end

    def handler_missing node
      error "no handler for node: #{node}"
    end

    # def on_NOOP _node
    #   0
    # end

    def on_EXPR node
      node.children.each do |node|
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
          cmd = process node

          begin
            return @env.send(*cmd.words) if @env.respond_to?(cmd.words.first)
          rescue ArgumentError => e
            puts e
            return 1
          end

          run *cmd.words
        else
          abort "expected one of :PIPELINE, :AND, :OR, :COMMAND"
        end
      end
      $CHILD_STATUS
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

      # pipeline.last.status
      $CHILD_STATUS
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

    private

    # @see {Msh::Env#run}
    def run *args
      @env.send :run, *args # NOTE: calling a private method here
    end
  end
end
