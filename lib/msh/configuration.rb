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
  # @example
  #
  # ```
  # Msh.configure do |c|
  #   c.repl = :pry
  # end
  # ```
  class Configuration
    # @return [bool] whether color is enabled (default: true)
    attr_accessor :color

    # @return [Integer] lines of history to keep (default: 2,048)
    attr_accessor :history_lines

    # @note This will call `binding.send :repl` for the provided repl
    # @return [Symbol] what kind of repl to use, IRB or Pry (default: :irb)
    attr_accessor :repl

    # @return [String]
    attr_accessor :file

    def initialize
      @color = true
      @history_lines = 2_048
      @repl = :irb # :pry
    end

    # Load first config file with `load`
    def self.load!
      paths = []

      if ENV.key? "XDG_CONFIG_HOME"
        paths << File.join(ENV["XDG_CONFIG_HOME"], "msh/config.rb")
      end

      paths += [
        File.join(Dir.home, ".mshrc"),
        File.join(Dir.home, ".config/msh/config.rb")
      ]

      load @file if @file = paths.find { |p| File.exist? p }
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
