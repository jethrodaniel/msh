# frozen_string_literal: true

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
