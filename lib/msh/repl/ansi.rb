# frozen_string_literal: true

require "readline"

require "msh/ansi"

module Msh
  class Repl
    # REPL to be used on a modern ANSI terminal, with Readline
    class Ansi < Repl
      include Colors

      def initialize
        super

        while line = ::Readline.readline(interpreter.prompt, true)&.chomp
          # don't add blank lines or duplicates to history
          if /\A\s*\z/ =~ line || Readline::HISTORY.to_a.dig(-2) == line
            Readline::HISTORY.pop
          end

          # FIXME: Make the lexer return [INTERPOLATION, "..."].
          #        Use a stack to match the brackets (`{` and `}`).
          line = interpreter.preprocess line
          lexer = Msh::Lexer.new line
          parser = Msh::Parser.new lexer.tokens
          interpreter.process parser.parse
        end
      rescue Interrupt
        puts "^C"
      end

      private

      def setup_readline
        Readline.completion_append_character = " "
        Readline.completion_proc = proc do |str|
          if str.start_with? "help"
            Msh::Documentation.help_topics.map do |topic|
              "help #{topic}"
            end + ["help"]
          else
            Dir[str + "*"].grep(/^#{Regexp.escape(str)}/)
          end
        end
      end
    end
  end
end
