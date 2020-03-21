# frozen_string_literal: true

require "pathname"
require "readline"

require "msh/cli"
require "msh/configuration"
require "msh/documentation"
require "msh/error"
require "msh/gemspec"
require "msh/version"

require "msh/lexer"
require "msh/parser"
require "msh/interpreter"

module Msh
  # Entry point for the `msh` command.
  #
  # Parses options/commands, then runs either interactively or on files.
  def self.start
    Msh::Documentation.setup_manpath!
    Msh::CLI.handle_options!

    return handle_files! if ARGV.size.positive?

    Msh::Interpreter.interactive
  end

  class << self
    private

    # handle `msh FILE...`
    def handle_files!
      ARGV.each do |file|
        parser = Msh::Parser.new
        nodes = parser.parse File.read(file)
        Msh::Interpreter.new.process(nodes)
      end
    end
  end
end
