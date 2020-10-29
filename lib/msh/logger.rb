require "logger" unless RUBY_ENGINE == "mruby"

require_relative "errors"
require_relative "ansi"

module Msh
  module Logger
    FORMATTER = -> severity, time, _progname, msg do
      color = case severity
              when "DEBUG" then :magenta
              when "INFO" then :green
              when "WARN" then :cyan
              when "ERROR" then :red
              when "FATAL", "UNKNOWN" then :red
              else
                raise Msh::Logger::Error, "invalid log level: #{severity}"
              end

      severity = severity.send(color).bold
      time = time.to_s.green.bold

      "[#{severity.ljust(5, ' ')}][#{time}]: #{msg}\n"
    end

    LEVELS = {
      "debug"   => ::Logger::DEBUG,
      "info"    => ::Logger::INFO,
      "warn"    => ::Logger::WARN,
      "error"   => ::Logger::ERROR,
      "fatal"   => ::Logger::FATAL,
      "unknown" => ::Logger::UNKNOWN
    }.freeze

    # Access a logger, to stdout (for now).
    #
    # Uses logging level ENV['MSH_LOG'], which can be WARN, INFO, etc
    def log
      logger = ::Logger.new STDOUT

      logger.formatter = FORMATTER
      logger.level = log_level

      logger
    end

    def log_level
      LEVELS[ENV["MSH_LOG"].to_s.downcase] || 6
    end
  end
end
