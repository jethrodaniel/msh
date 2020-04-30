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
  # ```
  # lex = Lexer.new "fortune | cowsay\n"
  # parser = Parser.new lex.tokens
  # interpreter = Interpreter.new parser.parse
  # ```
  # It also maintains its own environment, and has access to a user's config.
  #
  # == It operates like so:
  #
  # At startup, read the user's config.
  #
  # When {#process} is called, traverse the given AST, executing while
  # traversing each node.
  #
  # ==== command substitution
  #
  # TODO
  #
  # Command substitution works the same way as sh, i.e, a backtick string is
  # evaluated as the std out of running the string as a command.
  #
  # ```
  # echo `echo UP | tr '[:upper:]' '[:lower:]'` #=> `up`
  # ```
  #
  # Bash encourages the alternate `$()` syntax, which is admittedly, easier to
  # read.
  #
  # ==== ruby interpolation
  #
  # TODO
  #
  # Ruby interpolation is allowed anywhere using the familiar `#{}` syntax.
  # It is evaluated into WORDs, i.e, it can be used wherever command
  # substitution is allowed.
  #
  # ```
  # echo #{1 + 1} #=> 2
  # ```
  # ==== subshells
  #
  # TODO
  #
  # Subshells are the same as those in sh, i.e, they work like command
  # substitution, but run in a separate instance of the shell
  #
  # ```
  # (exit 1) #=> only exits the subshell, not the current shell
  # ```
  # === what's in a WORD? that which..
  #
  # A command shell's main job is to execute commands. A "command" is just a
  # series of WORD-like tokens, with optional redirections.
  #
  # These WORD-like tokens can be regular literals, string interpolation,
  # subshells, single and double quotes, or command substitution.
  #
  # Expansions occur just before the word is used, as in sh.
  #
  # === command resolution
  #
  # Commands are resolved by checking if any of the following match, in order
  #
  #   1. aliases
  #   1. functions / builtins
  #   1. executables
  #
  # If any match, the first match is used as the command. If any of the three
  # aren't matched, then the command is unresolved, or _not found_.
  #
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

    # @return [String]
    def prompt
      @env.prompt
    end

    # {#parse} calls this on unknown nodes
    def handler_missing node
      error "no handler for node: #{node}"
    end

    def on_NOOP _node
      0
    end

    def on_EXPR node
      process_all(node).last
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
      $CHILD_STATUS.exitstatus
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

    # 1. Perform redirects
    # 2. Expand words
    #   - could be command substitution or string interpolation
    # 3. Execute the command, first checking if a function, else ...
    #   - function
    #   - builtin
    #   - executable
    #
    # @param node [AST::Node] a :COMMAND node
    def on_COMMAND node
      redirs, words = node.children.partition { |n| n.type == :REDIRECT }

      redirs.each do |redir|
        # @todo perform the redirection
      end

      words.map! do |word|
        word.children.map do |w|
          case w.type
          when :INTERPOLATION
            value = w.children.first[2..-2]
            begin
              @env._evaluate value
            rescue NoMethodError => e
              puts e
            end
          when :LITERAL
            w.children.first
          end
        end.join
      end

      run *words
    end

    private

    # @see {Msh::Env#run}
    def run *args
      @env.send :run, *args # NOTE: calling a private method here
    end
  end
end
