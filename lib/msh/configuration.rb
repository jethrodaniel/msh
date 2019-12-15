# frozen_string_literal: true

# require "English" # TODO: optional
# require "abbrev" # TODO: use the std library for abbreviations, optional

# require "pry" # TODO: optionally swapable with irb, or equivalent REPL
# require "active_support/all" # TODO: optional in config

# TODO: optional readline
begin
  require "reline"
rescue
  abort "can't require 'reline'!"
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

    # Configure Msh like RSPec
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
