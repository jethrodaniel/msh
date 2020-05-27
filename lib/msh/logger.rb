# frozen_string_literal: true

begin
  require "logger"
rescue LoadError => e
  warn "#{e.class}: #{e.message}"
end

require "msh/errors"

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
