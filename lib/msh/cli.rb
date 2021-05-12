require_relative "../msh/optparse"
require_relative "../msh/version"
require_relative "../msh/interpreter"

module Msh
  module CLI
    BANNER = <<~B.freeze
      Usage:
          msh [options]... [file]...

      Options:
    B

    # @return [OptionParser]
    def self.option_parser argv
      OptionParser.new(argv) do |opts|
        opts.banner = Msh::CLI::BANNER

        opts.on "-h", "--help", "print this help" do
          puts opts
          exit 2
        end

        opts.on "-V", "--version", "show the version" do
          puts Msh::VERSION_STRING
          exit 2
        end

        opts.on "-c", "--command", "runs a string as shell input" do |cmd_string|
          abort "missing argument: -c" if cmd_string == ""

          interpreter = Msh::Interpreter.new
          exit interpreter.interpret cmd_string
        end
      end
    end

    # @todo configure Msh::Config here, if needed
    def self.handle_options! argv
      option_parser(argv).parse!
    rescue OptionParser::MissingArgument, OptionParser::InvalidOption => e
      abort e.message
    end
  end
end
