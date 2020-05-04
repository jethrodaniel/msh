# frozen_string_literal: true

require "English"
require "paint"

require "msh/logger"
require "msh/configuration"
require "msh/env"
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
  #
  # == It operates like so:
  #
  # When {#process} is called, traverse the given AST, executing while
  # visiting each node.
  #
  # ==== command substitution
  #
  # TODO
  #
  # Command substitution substitutes text inside `$(text)` as standard out of
  # running msh recursively with `text` as input.
  #
  # ```
  # echo $(echo UP | tr '[:upper:]' '[:lower:]') #=> `up`
  # ```
  #
  # The older backticks style is supported, but
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
  # substitution, but run don't return any output.
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
  # Expansions occur just before the word is used.
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
      Configuration.load!
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

    # rubocop:disable Naming/MethodName

    # @param node [Msh::AST::Node] :PROG
    # @return [Integer] exit status
    def on_PROG node
      process_all(node).last
    end

    # @param node [Msh::AST::Node] :AND or :OR
    # @return [Integer] exit status
    def on_NOOP _node
      0
    end

    # @param node [Msh::AST::Node] :COMMAND, :PIPELINE
    # @return [Integer] exit status
    def on_EXPR node
      process_all(node).last
    end

    # Run commands in a pipeline, i.e, in parallel with connected io streams.
    #
    # @param node [Msh::AST::Node] :PIPELINE
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

          begin
            exec *command_exec_args(cmd)
          rescue Errno::ENOENT => e # No such file or directory
            puts e.message
          end
        end

        stdout.close unless stdout == $stdout
        stdin.close  unless stdin == $stdin
        stdin = pipe.first
      end

      Process.waitall

      $CHILD_STATUS.exitstatus
    end

    # @param node [Msh::AST::Node] :OR
    # @return [Integer] exit status
    def on_OR node
      process node.children.first
      return $CHILD_STATUS if $CHILD_STATUS.exitstatus.zero?

      process node.children.last
    end

    # @param node [Msh::AST::Node] :AND
    # @return [Integer] exit status
    def on_AND node
      process node.children.first
      return $CHILD_STATUS unless $CHILD_STATUS.exitstatus.zero?

      process node.children.last
    end

    # 1. Perform redirects
    # 2. Expand words
    #   - could be command substitution or string interpolation
    # 3. Execute the command, first checking if a function, else ...
    #   - function
    #   - builtin
    #   - executable
    #
    # @param node [Msh::AST::Node] :CMD
    # @return [Integer] exit status
    def on_CMD node
      cmd, *args = command_exec_args(node)

      if @env.respond_to? cmd.to_sym
        @env.send cmd.to_sym, *args
        return
      end

      fork do
        begin
          exec *command_exec_args(node)
        rescue Errno::ENOENT => e # No such file or directory
          puts e.message
        end
      end

      Process.waitall

      $CHILD_STATUS.exitstatus
    end

    # rubocop:enable Naming/MethodName

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
