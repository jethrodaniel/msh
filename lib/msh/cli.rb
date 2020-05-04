# frozen_string_literal: true

require "optparse"

require "msh/version"
require "msh/gemspec"
require "msh/parser"
require "msh/interpreter"

module Msh
  module CLI
    BANNER = <<~B
      #{Msh::SUMMARY}

      Usage:
          msh [options]... [file]...

      Options:
    B

    # @return [OptionParser] the option parser for the `msh` command
    def self.option_parser
      OptionParser.new do |opts|
        opts.banner = Msh::CLI::BANNER

        opts.on "-h", "--help", "print this help" do
          puts opts
          exit 2
        end

        opts.on "-V", "--version", "show the version   (#{Msh::VERSION})" do
          puts "msh version #{Msh::VERSION}"
          exit 2
        end

        opts.on "--copyright", "--license", "show the copyright (MIT)" do
          puts File.read(Msh.root + "license.txt")
          exit 2
        end

        opts.on "-c  <cmd_string>", String, "runs <cmd_string> as shell input" do |cmd_string|
          cmd_string = ARGV.prepend(cmd_string).join " "
          interpreter = Msh::Interpreter.new
          exit interpreter.interpret cmd_string
        end
      end
    end

    # @todo configure Msh::Configuration here, if needed
    def self.handle_options!
      option_parser.parse!
    rescue OptionParser::MissingArgument, OptionParser::InvalidOption => e
      abort e.message
    end
  end
end
