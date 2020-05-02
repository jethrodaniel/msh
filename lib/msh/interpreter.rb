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
      raise "no handler for node: #{node}"
      # error "no handler for node: #{node}"
    end

    # @return [Integer] exit status
    def on_PROG node
      process_all(node).last
    end

    # @return [Integer] exit status
    def on_NOOP _node
      0
    end

    # @return [Integer] exit status
    def on_EXPR node
      process_all(node).last
    end

    # Run commands in a pipeline, i.e, in parallel with connected io streams.
    #
    # @param node [Msh::AST::Node] a :PIPELINE node
    # @return [Integer] exit status
    def on_PIPELINE node
      stdin = $stdin
      stdout = $stdout
      pipe = []

      node.children.each_with_index do |cmd, index|
        if index < node.children.size - 1
          pipe = IO.pipe
          stdout = pipe.last
        else
          stdout = $stdout
        end

        fork do
          if stdout != $stdout
            $stdout.reopen stdout
            stdout.close
          end
          if stdin != $stdin
            $stdin.reopen stdin
            stdin.close
          end
          exec *command_exec_args(cmd)
        end

        stdout.close unless stdout == $stdout
        stdin.close  unless stdin == $stdin
        stdin = pipe.first
      end

      Process.waitall

      $CHILD_STATUS.exitstatus
    end

    # @param node [Msh::AST::Node] an :AND or :OR node
    # @return [Integer] exit status
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
    # @param node [Msh::AST::Node] a :CMD node
    # @return [Integer] exit status
    def on_CMD node
      begin
        fork do
          exec *command_exec_args(node)
        end
      rescue Errno::ENOENT => e
        puts e.message
      end

      Process.waitall

      $CHILD_STATUS.exitstatus
    end

    private

    # Convert
    #
    #     s(:CMD,
    #       ...
    #
    # Into a string array
    #
    # @param node [Msh::AST::Node]
    # @return [Array<String>]
    def command_exec_args node
      redirs, words = node.children.partition { |n| n.type == :REDIRECT }

      redirs.each do |redir|
        # @todo perform the redirection
      end

      words.map! do |word|
        word.children.map do |w|
          case w.type
          when :INTERP
            value = w.children.first[2..-2]
            begin
              @env._evaluate value
            rescue NoMethodError => e
              puts e
            end
          when :LIT
            w.children.first
          end
        end.join
      end
    end
  end
end
