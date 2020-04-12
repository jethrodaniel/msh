# frozen_string_literal: true

require "logger"

require "msh/error"

module Msh
  module Logger
    class Error < Msh::Error; end

    FORMATTER = -> severity, time, _progname, msg do
      color = case severity
              when "DEBUG" then %i[magenta bright]
              when "INFO" then %i[green bright]
              when "WARN" then %i[cyan bright]
              when "ERROR" then %i[red bright]
              when "FATAL", "UNKNOWN" then %i[red bright]
              else
                raise Msh::Logger::Error, "invalid log level: #{severity}"
              end

      severity = Paint[severity, *color]
      time = Paint[time, :green]

      "[#{severity.ljust(5, ' ')}][#{time}]: #{msg}\n"
    end

    # Access a logger, to stdout (for now).
    #
    # Uses logging level ENV['MSH_LOG'], which can be WARN, INFO, etc
    def log
      logger = ::Logger.new $stdout

      logger.formatter = FORMATTER
      logger.level = log_level

      logger
    end

    def log_level
      case severity = ENV["MSH_LOG"].to_s.downcase
      when "debug"
        ::Logger::DEBUG
      when "info"
        ::Logger::INFO
      when "warn"
        ::Logger::WARN
      when "error"
        ::Logger::ERROR
      when "fatal"
        ::Logger::FATAL
      when "unknown"
        ::Logger::UNKNOWN
      when -> n { n&.match?(/\d/) && n.to_i >= 0 }
        severity.to_i
      else
        6 # Some large positive, so we don't log anything
      end
    end
  end
end
