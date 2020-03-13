# frozen_string_literal: true

# require "English" # TODO: optional
# require "abbrev" # TODO: use the std library for abbreviations, optional

# require "pry" # TODO: optionally swapable with irb, or equivalent REPL
# require "active_support/all" # TODO: optional in config

# TODO: optional readline
begin
  require "readline"
rescue
  abort "can't require 'readline'!"
end

module Msh
  def self.help_topics
    Msh.man_dir.glob("*.adoc.erb").map do |erb|
      File.basename(erb)
          .match(/msh\-(?<topic>\w+).1.adoc.erb/)&.[](:topic) || "msh"
    end
  end
end

Readline.completion_append_character = " "
Readline.completion_proc = proc do |str|
  if str.start_with? "help"
    Msh.help_topics.map do |topic|
      if topic == "msh"
        "help"
      else
        "help #{topic}"
      end
    end
  else
    Dir[str + "*"].grep(/^#{Regexp.escape(str)}/)
  end
end

module Msh
  class Configuration
    attr_accessor :color, :history, :prompt

    def initialize
      @color = true
      @history = {:size => 2_048}
      @prompt = "$"
    end
  end

  class << self
    # Is Msh currently testing? (need this to test the parser and lexer)
    def testing?
      ENV["MSH_TESTING"]
    end

    # Configure Msh like RSpec
    #
    # ```
    # Msh.configure do |c|
    #   c.color = true
    #   c.history = {:size => 10.megabytes}
    # end
    # ```
    #
    def configure
      yield configuration if block_given?
    end

    # Access Msh's configuration, like RSpec
    def configuration
      @configuration ||= Msh::Configuration.new
    end
  end
end
