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

          lexer = Msh::Lexer.new line
          parser = Msh::Parser.new lexer.tokens
          interpreter.process parser.parse
        end
      rescue Interrupt
        puts
      end
    end
  end
end
