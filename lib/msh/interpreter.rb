# frozen_string_literal: true

require "English"
require "paint"

require "msh/logger"
require "msh/errors"
require "msh/configuration"
require "msh/env"
require "msh/ast"
require "msh/lexer"
require "msh/parser"

module Msh
  # The interpreter executes an AST.
  #
  # @example
  #     msh = Msh::Interpreter.new
  #     msh.interpret "echo hi from msh!" #=> 0
  #
  # == command substitution
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
  # == ruby interpolation
  #
  # Ruby interpolation is allowed anywhere using the familiar `#{}` syntax.
  # It is evaluated into WORDs, i.e, it can be used wherever command
  # substitution is allowed.
  #
  # ```
  # echo #{1 + 1} #=> 2
  # ```
  # == subshells
  #
  # TODO
  #
  # Subshells are the same as those in sh, i.e, they work like command
  # substitution, but run don't return any output.
  #
  # ```
  # (exit 1) #=> only exits the subshell, not the current shell
  # ```
  # == what's in a WORD? that which..
  #
  # A command shell's main job is to execute commands. A "command" is just a
  # series of WORD-like tokens, with optional redirections.
  #
  # These WORD-like tokens can be regular literals, string interpolation,
  # subshells, single and double quotes, or command substitution.
  #
  # Expansions occur just before the word is used.
  #
  # == command resolution
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

    # create nodes with `s(:TOKEN, ...)`
    include ::AST::Sexp

    def initialize
      log.debug { "initialized new interpreter" }
      @env = Env.new
      @local_sh_variables = {}
      Configuration.load!
      setup_manpath!
    end

    # @param code [String]
    def interpret code
      parser = Parser.new code
      process parser.parse
    end

    # @return [String]
    def prompt
      @env.prompt
    end

    # Called on unknown node types
    def handler_missing node
      error "no handler for node: #{node}"
    end

    # @param node [Msh::AST::Node] :PROG
    # @return [Integer] exit status
    def on_PROG node
      process_all(node).last
    end

    # @param _node [Msh::AST::Node] :AND or :OR
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
    # Every command is a pipeline of size 1 - this consolidates the logic.
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

          exec_command cmd
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

    # @param node [Msh::AST::Node] :CMD
    # @return [Msh::AST::Node] :PIPELINE
    def on_CMD node
      exec_command node
    end

    # @note Evaluates INTERP and SUB nodes
    # @param node [Msh::AST::Node]
    # @return [String]
    def on_WORD node
      process_all(node).join
    end

    # @param node [Msh::AST::Node]
    # @return [String]
    def on_LIT node
      node.children.first
    end

    # @param node [Msh::AST::Node]
    # @return [String]
    def on_SUB _node
      error "unimplemented"
    end

    # @param node [Msh::AST::Node]
    # @return [String]
    def on_ASSIGN node
      var, value = *node.children
      ENV[var] = value
      # error "unimplemented"
    end

    # @param node [Msh::AST::Node]
    # @return [String]
    def on_VAR node
      var = node.children.first[1..-1]

      local_value = local_sh_variables.dig(var)
      return local_value if local_value

      ENV[var].to_s
    end

    # @param node [Msh::AST::Node]
    # @return [String]
    def on_INTERP node
      value = node.children.first[2..-2]
      begin
        @env._evaluate value
      rescue NoMethodError => e
        error e.message
      end
    end

    private

    attr_reader :local_sh_variables

    # 1. Expand/create words fit for {Kernel#exec}; word parts could be
    #   - interpolation
    #   - literals
    #   - command substitution
    # 1. Perform variable assignments
    # 1. Perform redirects
    # 1. Execute the command, which could be a
    #   - builtin
    #   - executable
    #
    # @note Calls {Kernel#exec}
    # @param node [Msh::AST::Node] :CMD
    def exec_command node
      command = command_from_node node

      if command.just_assignments?
        local_sh_variables.merge! command.vars
        return
      end

      return if command.words.empty?

      cmd, args = command.words.first.to_sym, *command.words[1..-1]
      return @env.send cmd.to_sym, *args if @env.respond_to? cmd.to_sym

      pid = fork do
        ENV.merge! command.vars

        begin
          exec *command.words
        rescue Errno::ENOENT => e # No such file or directory
          abort e.message
        end
      end

      Process.wait pid

      $CHILD_STATUS.exitstatus
    end

    Command = Struct.new :words, :vars, :redirs, :keyword_init => true do
      # @todo `> new`
      def just_assignments?
        words&.empty? # && redirs&.empty?
      end
    end

    # @param node [Msh::AST::Node] :CMD
    # @return [Command]
    def command_from_node node
      words = []
      vars = {}

      node.children.each do |word|
        case word.type
        when :WORD
          words << process(word)
        when :ASSIGN
          var, value = *process_all(word)
          vars[var] = value
        when :REDIR
          error "unimplemented"
        else
          error "unknown type #{word.type}"
        end
      end

      Command.new :words => words,
                  :vars => vars
    end

    # @param msg [String]
    def error msg
      raise Errors::InterpreterError, msg
    end

    # Add Msh's manpages to the current MANPATH
    #
    # @todo: what the "::" means (need it to work)
    def setup_manpath!
      manpaths = ENV["MANPATH"].to_s.split(File::PATH_SEPARATOR)
      manpaths << Msh.root.join("man").realpath.to_s
      ENV["MANPATH"] = manpaths.compact.join(File::PATH_SEPARATOR) + "::"
    end
  end
end
