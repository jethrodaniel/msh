# frozen_string_literal: true

require "irb"

# prevent IRB from polluting Readline history
IRB.conf[:SAVE_HISTORY] = nil

module Msh
  class Interpreter
    class Env
      def initialize
        @binding = binding
      end

      def evaluate input
        @binding.eval("\"#{input}\"", *@binding.source_location)
      end

      def history
        size = 3
        Readline::HISTORY.to_a.tap do |h|
          size = h.size.to_s.chars.size
        end.each.with_index(1) do |e, i| # rubocop:disable Style/MultilineBlockChain
          puts "#{i.to_s.ljust(size, ' ')} #{e}"
        end
        0
      end
      alias hist history

      def help *topics
        cmd = if topics.empty?
                %w[man msh]
              else
                %w[man] + topics.map { |t| "msh-#{t}" }
              end
        run(*cmd)
      end

      def lexer *files
        Msh::Lexer.start files
        0
      end

      def parser *files
        Msh::Parser.start files
        0
      end

      def repl
        evaluate '#{@binding.irb}' # rubocop:disable Lint/InterpolationCheck
      end

      def exit
        puts "goodbye! <3"
        exit
      end
      alias q exit
      alias quit exit

      private

      # Execute a command via `fork`, wait for the command to finish
      #
      # TODO: spawn, so this can be more platform-independent
      #
      # @param args [Array<String>] args to execute
      # @return [Void]
      def run *args
        unless args.all? { |a| a.is_a? String }
          abort "expected Array<String>, got `#{args.class}:#{args.inspect}`"
        end

        pid = fork do
          exec *args
        rescue Errno::ENOENT => e
          puts e.message
        end

        Process.wait pid

        $CHILD_STATUS
      end
    end
  end
end
