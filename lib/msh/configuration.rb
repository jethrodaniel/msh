# frozen_string_literal: true

module Msh
  # Configure Msh.
  #
  # The user's config file is the first of
  #
  # - `~/.mshrc`
  # - `$XDG_CONFIG_HOME/msh/config.rb`
  # - `~/.config/msh/config.rb`
  #
  # It is Ruby, and is executed in the current shell, like string interpolation.
  #
  # A typical example might be
  #
  # ```
  # Msh.configure do |c|
  #   c.repl = :pry
  # end
  #
  # def prompt
  #   "$ "
  # end
  # ```
  class Configuration
    # @return [bool] whether color is enabled (default: true)
    attr_accessor :color

    # @return [Integer] lines of history to keep (default: 2,048)
    attr_accessor :history_lines

    # @return [Symbol] what kind of repl to use, IRB or Pry (default: :irb)
    attr_accessor :repl

    def initialize
      @color = true
      @history_lines = 2_048
      @repl = :irb # :pry
    end
  end

  # Configure Msh with a block
  #
  # ```
  # Msh.configure do |c|
  #   c.repl = :pry
  # end
  # ```
  def self.configure
    yield configuration if block_given?
  end

  # Access Msh's configuration
  def self.configuration
    @configuration ||= Msh::Configuration.new
  end
end
