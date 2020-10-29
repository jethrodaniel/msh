require_relative "readline"
require_relative "interpreter"

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
      @checker = Msh::Readline::TerminationChecker.new

      puts "#{VERSION_STRING} (`?` for help)"

      unless RUBY_ENGINE == "mruby"
        Reline.prompt_proc = -> buffer do
          return [interpreter.prompt] + ["> "] * buffer.size if buffer.size > 1

          [interpreter.prompt]
        end
      end

      with_interrupt_handling do
        input_loop do |line|
          interpreter.interpret line
        end
      end
    end

    private

    # mruby has no interrupts
    def with_interrupt_handling
      if RUBY_ENGINE == "mruby"
        yield
        return
      end

      begin
        yield
      rescue Interrupt
        puts "^C"
        exit 0
      end
    end

    # @yield [String] the next line of input
    def input_loop
      while line = Msh::Readline.readline(interpreter.prompt, true) { |code| @checker.terminated?(code) }
        yield line
      end
    end
  end
end
