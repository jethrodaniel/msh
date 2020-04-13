# frozen_string_literal: true

require "msh/cli"
require "msh/documentation"
require "msh/repl"

module Msh
  # Entry point for the `msh` command.
  #
  # Parses options/commands, then runs either interactively or on files.
  #
  # If the `NO_READLINE` environment variable is set, readline won't be used.
  def self.start
    Msh::Documentation.setup_manpath!
    Msh::CLI.handle_options!

    if ARGV.size.zero?
      if ENV["NO_READLINE"]
        Msh::Repl::Simple.new
      else
        Msh::Repl::Ansi.new
      end
    else
      interpreter = Msh::Interpreter.new
      ARGV.each do |file|
        lexer = Msh::Lexer.new File.read(file)
        parser = Msh::Parser.new lexer.tokens
        interpreter.process parser.parse
      end
    end
  end
end
