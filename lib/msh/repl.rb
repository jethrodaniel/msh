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

    def with_interrupt_handling &block
      return with_interrupt_handling_mruby(&block) if RUBY_ENGINE == "mruby"

      with_interrupt_handling_ruby(&block)
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

    # @yield [String]
    def input_loop
      if $stdin.tty?
        if ENV["NO_READLINE"]
          while line = ARGF.gets&.chomp
            yield line
          end
        else
          # while line = ::Reline.readmultiline(interpreter.prompt, true) { |_code| next true;interpreter.terminated? }
          while line = Msh::Readline.readline(interpreter.prompt)
            yield line
          end
        end
      else
        while line = ARGF.gets&.chomp
          yield line
        end
      end
    end

    def add_to_history line
      Msh::Readline.add_to_history line
    end
  end
end
