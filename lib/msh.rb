# frozen_string_literal: true

require "msh/cli"
require "msh/documentation"
require "msh/interpreter"
require "msh/parser"

module Msh
  # Entry point for the `msh` command.
  #
  # Parses options/commands, then runs either interactively or on files.
  def self.start
    Msh::Documentation.setup_manpath!
    Msh::CLI.handle_options!

    return Msh::Interpreter.interactive if ARGV.size.zero?

    ARGV.each do |file|
      parser = Msh::Parser.new
      nodes = parser.parse File.read(file)
      Msh::Interpreter.new.process(nodes)
    end
  end
end
