# frozen_string_literal: true

require "msh/readline"
require "msh/interpreter"

module Msh
  # A read-eval print loop (REPL), continuously reads in user input, then
  # executes it.
  #
  # This is separate from an interpreter, which is only responsible for
  # interpreting (i.e, executing) code. For instance, the interpreter is still
  # responsible for the non-term specific things, such as the user's prompt,
  # but the REPL then needs to print that prompt.
  #
  # ```
  # Repl.new # start up a new REPL
  # ```
  class Repl
    # @return [Interpreter]
    attr_reader :interpreter

    def initialize
      @interpreter = Msh::Interpreter.new
      puts "Welcome to msh v#{Msh::VERSION} (`?` for help)" if $stdin.tty?

      with_interrupt_handling do
        input_loop do |line|
          add_to_history line
          interpreter.interpret line
        end
      end
    end

    private

    # mruby has no interrupts
    def with_interrupt_handling &block
      if RUBY_ENGINE == "mruby"
        with_interrupt_handling_mruby(&block)
      else
        with_interrupt_handling_ruby(&block)
      end
    end

    def with_interrupt_handling_ruby
      yield
    rescue Interrupt
      puts "^C"
      exit 0
    end

    def with_interrupt_handling_mruby
      yield
    end

    # @yield [String] the next line of input
    def input_loop
      get_line = if !$stdin.tty? || ENV["NO_READLINE"]
                   -> { ARGF.gets&.chomp }
                 else
                   -> { Msh::Readline.readline(interpreter.prompt) }
                 end

      while line = get_line.call
        yield line
      end
    end

    def add_to_history line
      Msh::Readline.add_to_history line
    end
  end
end
