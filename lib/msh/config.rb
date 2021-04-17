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
  #     Msh.configure do |c|
  #       c.repl = :pry
  #     end
  #     Msh.config.repl #=> :pry
  #     Msh.config.color #=> true
  class Config
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

    def config_text
      paths = []

      paths << File.join(ENV["XDG_CONFIG_HOME"], "msh/config.rb") if ENV.key? "XDG_CONFIG_HOME"

      paths += [
        File.join(Dir.home, ".mshrc"),
        File.join(Dir.home, ".config/msh/config.rb")
      ]

      paths.select { |p| File.exist?(p) }.map { |f| File.read(f) }.join("\n")
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
    yield config if block_given?
  end

  # Access Msh's config
  def self.config
    @config ||= Msh::Config.new
  end
end
