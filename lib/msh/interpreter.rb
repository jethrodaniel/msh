require "English" unless RUBY_ENGINE == "mruby"

require_relative "logger"
require_relative "config"
require_relative "errors"
require_relative "evaluator"
require_relative "lexer"
require_relative "parser"
require_relative "pipe"

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
    # include ::AST::Processor::Mixin
    def process node
      return if node.nil?

      meth = :"on_#{node.type}"
      return send(meth, node) || 0 if respond_to?(meth)

      handler_missing node
    end

    # def process_all *nodes
    def process_all node
      node.to_a.map { |n| process n }
    end

    # create nodes with `s(:TOKEN, ...)`
    include AST::Sexp

    Redirect = Struct.new :io, :dup, :file

    def initialize
      @evaluator = Evaluator.new
      @local_sh_variables = {}

      @config = Config.new
      interpret @config.config_text

      setup_manpath! unless RUBY_ENGINE == "mruby"
    end

    # @param code [String]
    def interpret code
      parser = Parser.new code
      process parser.parse
    end

    # @return [String]
    def prompt
      @evaluator.call_no_exit_value :prompt
    end

    # Called on unknown node types
    def handler_missing node
      error "no handler for node: #{node}"
    end

    # rubocop:disable Naming/MethodName

    # @param node [Msh::AST::Node] :PROG
    # @return [Integer] exit status
    def on_PROG node
      process_all(node).last
    end

    # @return [Integer] exit status
    def on_NOOP _node
      @last_command_status = 0
    end

    # @param node [Msh::AST::Node] :COMMAND, :PIPELINE
    # @return [Integer] exit status
    def on_EXPR node
      @last_command_status = process_all(node).last
    end

    # Run commands in a pipeline, i.e, in parallel with connected io streams.
    #
    # Every command is a pipeline of size 1 - this consolidates the logic.
    #
    # @param node [Msh::AST::Node] :PIPELINE
    # @return [Integer] exit status
    def on_PIPELINE node
      p = Pipeline.new node.children
      p.run { |c| process c.cmd }

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
      parts        = node.children.group_by(&:type)
      words        = process_all(parts[:WORD]).reject(&:empty?)       # [a, b]
      assignments  = process_all(parts[:ASSIGN]).reduce({}, :merge)   # {a=>b}

      if words.empty?
        local_sh_variables.merge! assignments
        return 0
      end

      prev_env = assignments.merge(local_sh_variables)
                            .transform_values { |v| ENV[v] }

      # r.map { |fd| "fd ##{fd.fileno}, open: #{!fd.closed?}" }
      redirections = process_all(parts[:REDIRECT]).flatten

      begin
        ENV.merge! assignments.merge(local_sh_variables)

        if @evaluator.has?(words.first)
          exec_builtin words, redirections
        else
          exec_command words, redirections
        end
      ensure
        redirections.each do |redirect|
          redirect.file.close
          redirect.io.reopen redirect.dup
        end

        ENV.merge! prev_env
      end
    end

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

    # @return [String]
    def on_LAST_STATUS _node
      return @last_command_status if @last_command_status

      warn "no last command to retrieve status for"

      ""
    end

    # @return [String]
    def on_SUB _node
      error "unimplemented"
    end

    # @param node [Msh::AST::Node]
    # @return [String]
    def on_ASSIGN node
      var, value = *process_all(node)
      {var => value}
    end

    # @param node [Msh::AST::Node]
    # @return [String]
    def on_VAR node
      var = node.children.first[1..-1]

      local_value = local_sh_variables[var]
      return local_value if local_value

      ENV[var].to_s
    end

    # @param node [Msh::AST::Node]
    # @return [String]
    def on_INTERP node
      value = node.children.first[2..-2]
      begin
        @evaluator.eval(value) || ""
      rescue NoMethodError => e
        error e.message
      end
    end

    # @param node [Msh::AST::Node]
    # @return [Array<Array<IO>>]
    def on_REDIRECT node
      process_all(node)
    end

    # @param node [Msh::AST::Node]
    # @return [Array<IO>]
    def on_REDIRECT_OUT node
      file_descriptor, output = node.children
      io = IO.new(file_descriptor, "r")
      dup = io.dup
      file = File.open output, "w"

      io.reopen file, "w"

      Redirect.new io, dup, file
    end

    # @param node [Msh::AST::Node]
    # @return [Array<IO>]
    def on_REDIRECT_IN node
      file_descriptor, output = node.children
      io = IO.new(file_descriptor, "r")
      dup = io.dup
      file = File.open output, "r"

      io.reopen file

      Redirect.new io, dup, file
    end

    # @param node [Msh::AST::Node]
    # @return [Array<IO>]
    def on_APPEND_OUT node
      file_descriptor, output = node.children
      io = IO.new(file_descriptor, "r")
      dup = io.dup
      file = File.open output, "a"

      io.reopen file

      Redirect.new io, dup, file
    end

    # @param node [Msh::AST::Node]
    # @return [Array<IO>]
    def on_AND_REDIRECT_RIGHT node
      file_descriptor, output = node.children

      r = process s(:REDIRECT_OUT, file_descriptor, output)
      # r.io.sync = true

      err_io = IO.new(2)
      dup    = err_io.dup
      err_io.reopen r.io # , "a"

      err = Redirect.new err_io, dup, r.file

      # err_r = process(s(:APPEND_OUT, 2, r.file.dup))
      # err_r.io.sync = true

      [r, err]
    end

    # rubocop:enable Naming/MethodName

    private

    attr_reader :local_sh_variables

    def exec_builtin words, _redirections
      @evaluator.call(*words)
    rescue ArgumentError => e
      puts e.message
    end

    def exec_command words, _redirections
      @evaluator.call(:run, *words)
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
      manpaths << File.join(Msh.root, "man").to_s
      ENV["MANPATH"] = "#{manpaths.compact.join(File::PATH_SEPARATOR)}::"
    end
  end
end
