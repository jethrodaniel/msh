module Msh
  module Config
    def self.config_text
      paths = []

      paths << File.join(ENV["XDG_CONFIG_HOME"], "msh/config.msh") if ENV.key? "XDG_CONFIG_HOME"

      paths += [
        File.join(Dir.home, ".mshrc"),
        File.join(Dir.home, ".config/msh/config.msh")
      ]

      paths.select { |p| File.exist?(p) }.map { |f| File.read(f) }.join("\n")
    end
  end
end
