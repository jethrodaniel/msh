# frozen_string_literal: true

require "msh/cli"
require "msh/documentation"
require "msh/interpreter"
require "msh/parser"
require "msh/repl"

module Msh
  # Entry point for the `msh` command.
  #
  # Parses options/commands, then runs either interactively or on files.
  def self.start
    Msh::Documentation.setup_manpath!
    Msh::CLI.handle_options!

    if ARGV.size.zero?
      if ENV['NO_COLOR']
        Msh::Repl::Simple.new
      else
        Msh::Repl::Ansi.new
      end
    else
      abort "unimplemented"
      # ARGV.each do |file|
      #   parser = Msh::Parser.new
      #   nodes = parser.parse File.read(file)
      #   Msh::Interpreter.new.process(nodes)
      # end
    end
  end
end
