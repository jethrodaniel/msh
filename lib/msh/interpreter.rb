# frozen_string_literal: true

require "English" # for $CHILD_STATUS

require "msh/lexer"
require "msh/parser"
require "msh/ast"
require "msh/gemspec"

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
# Our entry point is the root of the grammar
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

    # p = Preprocessor.new
    # e = Env.new
    #
    #
    class Preprocessor
      def initialize; end
    end

    class Env # < BasicObject
      def initialize; end

      def respond_to? meth
        # TODO: this is costly? hardcode these 8 methods or so?
        # return false if BasicObject.new.respond_to?(meth)
        return false if Object.new.respond_to?(meth)

        super
      end

      # def run meth, *args, &block
      #   instance_eval do
      #     send meth, *args, &block
      #   end
      # end

      def run input
        t = binding.eval("\"#{input}\"", *binding.source_location) # rubocop:disable Style/EvalWithLocation, Security/Eval
        t
      end
    end

    # Run the interpreter interactively.
    #
    # This is the main point of the shell, really.
    #
    # @return [Void]
    def self.interactive # rubocop:disable Metrics/AbcSize
      env = Env.new
      interpreter = Msh::Interpreter.new

      while line = Readline.readline("interpreter> ", true)&.chomp
        # don't add blank lines or duplicates to history
        if /\A\s*\z/ =~ line || Readline::HISTORY.to_a.dig(-2) == line
          Readline::HISTORY.pop
        end

        case line
        when "q", "quit", "exit"
          puts "goodbye! <3"
          exit
        else
          begin
            parser = Msh::Parser.new

            begin
              line = env.run line
              # puts "[line] #{line.inspect}"
            rescue NoMethodError => e
              puts e
            end

            nodes = parser.parse line

            interpreter.process nodes
          rescue MissingCommandError, Racc::ParseError => e
            p e.pretty_message
          rescue Msh::Lexer::ScanError => e
            p e.pretty_message(parser.lexer)
          end
        end
      end
    rescue Interrupt => e
      puts "^C"
      run *%w[stty sane]
      # run *%w[tput rs1] # clear
    end

    # Execute a command via `fork`, wait for the command to finish
    #
    # TODO: spawn, so this can be more platform-independent
    #
    # @param args [Array<String>] args to execute
    # @return [Void]
    def self.run *args
      unless args.all? { |a| a.is_a? String }
        abort "expected Array<String>, got `#{args.class}:#{args.inspect}`"
      end

      pid = fork do
        begin
          exec *args
        rescue Errno::ENOENT => e
          puts e.message
        end
      end

      Process.wait pid

      $CHILD_STATUS
    end

    def run *args
      self.class.run *args
    end

    def on_NOOP _node
      0
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
        words = process(node).words

        # handle `help [topic]...`
        help_topics = words.drop 1
        cmd = if help_topics.empty?
                %w[man msh]
              else
                %w[man] + help_topics.map { |t| "msh-#{t}" }
              end
        return run(*cmd) if words.first == "help"

        # history builtin
        if %(history hist).include? words.first
          size = 3
          Readline::HISTORY.to_a.tap do |h|
            size = h.size.to_s.chars.size
          end.each.with_index(1) do |e, i|
            puts "#{i.to_s.ljust(size, ' ')} #{e}"
          end
          return 0
        end

        case words.first
        when "lexer"
          return Msh::Lexer.start(words.drop(1))
        when "parser"
          return Msh::Parser.start(words.drop(1))
        end

        run *words
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
  end
end
