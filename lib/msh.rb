require "English" unless RUBY_ENGINE == "mruby"
require "pathname" unless RUBY_ENGINE == "mruby"

require "msh/mruby"
require "msh/backports"
require "msh/core_extensions"
require "msh/cli"
require "msh/repl"

module Msh
  def self.root
    raise Error, "`Msh.root` is unsupported" if RUBY_ENGINE == "mruby"

    path = Dir.pwd

    begin
      path = Gem::Specification.find_by_name("msh").gem_dir
    rescue Gem::MissingSpecError => e
      warn "`msh` not installed. Assuming root dir is the current dir"
    end
    Pathname.new(path)
  end

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
