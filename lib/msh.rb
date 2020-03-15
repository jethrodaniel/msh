# frozen_string_literal: true

require "msh/version"
require "msh/error"
require "msh/configuration"
require "msh/gemspec"
require "msh/documentation"

require "msh/lexer"
require "msh/parser"
require "msh/interpreter"

require "msh/ruby_version"
require "msh/extensions" if Msh.ruby_2_4? || Msh.ruby_2_5?

# msh is a happy little ruby shell.
#
# It's goal is to enable you to write less shell, and more Ruby.
#
module Msh
  # Entry point for msh.
  #
  # Parses options/commands, then runs either interactively or on files.
  #
  # @todo: make Msh.start _only_ run the basic interactive, like Pry.start
  # @todo: cli, command classes
  #
  # @return [void]
  def self.start
    setup_manpath
    handle_options!

    if ARGV.size.positive?
      handle_files!
    else
      Msh::Interpreter.interactive
    end
  end

  BANNER = <<~B
    #{gemspec.summary}

    Usage:
        msh [options]... [file]...

    Options:
  B

  class << self
    private

    # handle `msh FILE...`
    # @return [void]
    def handle_files!
      ARGV.each do |file|
        parser = Msh::Parser.new
        nodes = parser.parse File.read(file)
        Msh::Interpreter.new.process(nodes)
      end
    end

    # Handle `-h`, `--help`, etc
    #
    # @todo configure Msh::Configuration here, if needed
    # @return [void]
    def handle_options!
      option_parser.parse!
    rescue OptionParser::MissingArgument => e
      abort e.message
    rescue OptionParser::InvalidOption => e
      abort e.message
    end

    # @return [OptionParser] the option parser for the `msh` command
    def option_parser # rubocop:disable Metrics/AbcSize
      OptionParser.new do |opts|
        opts.banner = BANNER

        opts.on "-h", "--help", "print this help" do
          puts opts
          exit 2
        end

        opts.on "-V", "--version", "show the version   (#{Msh::VERSION})" do
          puts "msh version #{Msh::VERSION}"
          exit 2
        end

        opts.on "--copyright", "--license", "show the copyright (MIT)" do
          puts File.read(Pathname.new(__dir__) + "../license.txt")
          exit 2
        end

        opts.on "-c  <cmd_string>", String, "runs <cmd_string> as shell input" do |cmd_string| # # rubocop:disable Metrics/LineLength
          cmd_string = ARGV.prepend(cmd_string).join " "
          ast = Msh::Parser.new.parse cmd_string
          exit Msh::Interpreter.new.process(ast).exitstatus
        end
      end
    end

    # Add this gem's manpages to the current MANPATH
    #
    # @todo: what the "::" means (need it to work)
    def setup_manpath
      manpaths = ENV["MANPATH"].to_s.split(File::PATH_SEPARATOR)
      manpaths << Msh.man_dir.realpath.to_s
      ENV["MANPATH"] = manpaths.compact.join(File::PATH_SEPARATOR) + "::"
    end
  end
end
