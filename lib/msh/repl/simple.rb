# frozen_string_literal: true

module Msh
  class Repl
    # REPL that outputs simple, non-ANSI plaintext
    class Simple < Repl
      def initialize
        super

        loop do
          print "msh λ "
          line = gets&.chomp

          abort "^D" if line.nil?

          puts line
        end
      rescue Interrupt
        puts
      end
    end
  end
end
