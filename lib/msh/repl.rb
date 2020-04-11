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
    class Error < Msh::Error; end

    # @param [Lexer]
    attr_reader :lexer

    # @param [Parser]
    attr_reader :parser

    # @param [Interpreter]
    attr_reader :interpreter

    def initialize
      @interpreter = Msh::Interpreter.new
      puts "Welcome to msh v#{Msh::VERSION} (`?` for help)"
    end
  end
end

require "msh/repl/simple"
require "msh/repl/ansi"
