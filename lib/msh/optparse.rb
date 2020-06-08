# frozen_string_literal: true

module Msh
  # Stupid simple option parser _clone_, since optparse is pretty heavyweight,
  # and pulls in onigmo (regexp) on mruby.
  class OptionParser
    class MissingArgument < ArgumentError; end
    class InvalidOption < ArgumentError; end

    Action = Struct.new(:short, :long, :desc, :block) do
      def help_line_opts
        "    #{short}, #{long}"
      end
    end

    attr_accessor :banner

    def initialize
      @actions = []
      @banner = nil
      yield self if block_given?
    end

    def to_s
      longest_opts = @actions.max_by { |a| a.help_line_opts.size }
                             .help_line_opts
                             .size + 2
      lines = []

      @actions.sort_by { |a| [a.short, a.long] }.each do |a|
        lines << a.help_line_opts.ljust(longest_opts, " ") + a.desc
      end

      lines.join("\n")
    end

    def on short, long, desc, &block
      @actions << Action.new(short, long, desc, block)
    end

    def parse!
      switches, files = ARGV.partition { |e| e.start_with?("-") }

      switches.each do |switch|
        action = if switch.start_with?("--")
                   @actions.find { |a| a.long == switch }
                 else
                   @actions.find { |a| a.short == switch }
                 end

        if action
          puts(@banner) if action.long == "--help"
          action.block.(files.join(" "))
        else
          raise InvalidOption, "invalid option `#{switch}`"
        end
      end
    end
  end
end
