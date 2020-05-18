# frozen_string_literal: true

require "msh/lexer"
require "msh/parser"
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
      begin
        stty_save = `stty -g`.chomp
      rescue
        warn "error when performing init setup command `stty -g`"
      end

      @interpreter = Msh::Interpreter.new
      puts "Welcome to msh v#{Msh::VERSION} (`?` for help)"

      input_loop do |line|
        add_to_history line
        interpreter.interpret line
      end
    rescue Interrupt
      puts "^C"
      `stty #{stty_save}` if stty_save
      exit 0
    ensure
      `stty #{stty_save}` if stty_save
      puts
    end

    private

    # @yield [String]
    def input_loop
      if ENV["NO_READLINE"]
        while line = gets&.chomp
          yield line
        end
      else
        while line = ::Reline.readline(interpreter.prompt, true)&.chomp
          yield line
        end
      end
    end

    def add_to_history line
      return if ENV["NO_READLINE"]

      # don't add blank lines or duplicates to history
      return unless /\A\s+\z/ =~ line || Reline::HISTORY.to_a.dig(-2) == line

      Reline::HISTORY.pop
    end
  end
end
