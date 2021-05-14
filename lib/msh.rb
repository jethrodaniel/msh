require "msh/backports"
require "msh/mruby"
require "msh/cli"
require "msh/repl"

module Msh
  # Entry point for the `msh` command.
  #
  # Parses options/commands, then runs either interactively or on files.
  def self.start argv = ARGV
    Msh::CLI.handle_options! argv

    return Msh::Repl.new if argv.size.zero?

    interpreter = Msh::Interpreter.new

    argv.each do |file|
      abort "`#{file}` not found" unless File.file?(file)
      interpreter.interpret File.read(file)
    end
  end
end
