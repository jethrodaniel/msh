# frozen_string_literal: true

require "readline"

module Msh
  def self.help_topics
    Msh.root.join('man').glob("*.adoc.erb").map do |erb|
      File.basename(erb)
          .match(/msh\-(?<topic>\w+).1.adoc.erb/)
          &.[](:topic)
    end.compact # `msh.1.adoc.erb` makes a nil
  end
end

Readline.completion_append_character = " "
Readline.completion_proc = proc do |str|
  if str.start_with? "help"
    Msh.help_topics.map { |topic| "help #{topic}" } + ["help"]
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

  # Configure Msh like RSpec
  #
  # ```
  # Msh.configure do |c|
  #   c.color = true
  #   c.history = {:size => 10.megabytes}
  # end
  # ```
  #
  def self.configure
    yield configuration if block_given?
  end

  # Access Msh's configuration, like RSpec
  def self.configuration
    @configuration ||= Msh::Configuration.new
  end
end
