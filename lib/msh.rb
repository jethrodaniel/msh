# frozen_string_literal: true

require "msh/version"
require "msh/error"
require "msh/configuration"

require "msh/lexer"
require "msh/parser"
require "msh/interpreter"

# msh is a happy little ruby shell.
#
# It's goal is to enable you to write less shell, and more Ruby.
#
module Msh
  # Lazy way to not type all the stuff from the gemspec.
  #
  # @return [Gem::Specification] this gem's gemspec
  def self.gemspec
    @gemspec ||= Gem::Specification.find_by_name "msh"
  end

  # Entry point for msh.
  #
  # Parses options/commands, then runs either interactively or on files.
  #
  # @return [void]
  def self.start
    handle_options!
    handle_args!

    if ARGV.size.positive?
      handle_files!
    else
      puts LOGO
      Msh::Interpreter.interactive
    end
  end

  # `msh --help`
  BANNER = <<~MSG
    Usage: msh <command> [options]... [file]...

    #{gemspec.summary}

    To file issues or contribute, see #{gemspec.homepage}.

    commands:
        lexer                            run the lexer
        parser                           run the parser
        <blank>                          run the interpreter

    options:
  MSG

  LOGO = <<~P

    ______________________________________________________________________
        ^__^                               __                  ^__^
        (oo)\\_______      .--------.-----.|  |--.      _______/(oo)
       (__)\\       )\\/\\   |        |__ --||     |  /\\/(        /(__)
           ||----w |      |__|__|__|_____||__|__|      | w----||
    _______||_____||___________________________________||_____||__________

  P

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

    # handle `msh COMMAND`, then exit
    # @return [void]
    def handle_args!
      case ARGV.first
      when "lexer"
        ARGV.shift
        Msh::Lexer.start
        exit
      when "parser"
        ARGV.shift
        Msh::Parser.start
        exit
      end
    end

    # Handle `-h`, `--help`, etc
    #
    # @todo configure Msh::Configuration here, if needed
    # @return [void]
    def handle_options!
      option_parser.parse!
    rescue OptionParser::InvalidOption => e
      abort e.message
    end

    # @return [OptionParser] the option parser for the `msh` command
    def option_parser
      OptionParser.new do |opts|
        opts.banner = BANNER

        opts.on "-h", "--help", "print this help" do
          puts opts
          exit
        end

        opts.on "-V", "--version", "show the version" do
          puts "msh version #{Msh::VERSION}"
          exit
        end

        opts.on "--copyright", "--license", "show the copyright" do
          puts File.read(Pathname.new(__dir__) + "../license.txt")
          exit
        end
      end
    end
  end
end
