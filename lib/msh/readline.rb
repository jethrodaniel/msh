module Msh
  module Readline
    # TODO: color via the ast, not via tokens
    # TODO: integrate with completion, like fish
    class SyntaxHighlighter
      attr_reader :code

      def initialize code
        lex = Msh::Lexer.new code

        @code = lex.tokens.map do |t|
          case t.type
          when :WORD
            t.value.blue
          when :PIPE, :AND, :OR
            t.value.cyan
          when :EOF
            ""
          else
            t.value
          end
        end.join
      end
    end

    class TerminationChecker
      NON_FINISHED_CHARS = %w[&& || |].freeze

      # TODO: in block, etc
      def terminated? code
        code.gsub!(/\n*$/, "").concat("\n")
        NON_FINISHED_CHARS.none? { |c| code.strip.end_with? c }
      end
    end

    def self.readline prompt, keep_history = true, &block
      if Object.const_defined? :Reline
        if block_given?
          return ::Reline.readmultiline(prompt, keep_history, &block)
        else
          return ::Reline.readline(prompt, keep_history)
        end
      end

      print prompt
      gets&.chomp
    end
  end
end

unless RUBY_ENGINE == "mruby"
  require "reline"

  # Reline.prompt_proc = -> buffer do
  #   return [interpreter.prompt] + ["> "] * buffer.size if buffer.size > 1

  #   [interpreter.prompt]
  # end

  Reline.completion_proc = -> input do
    opts = Dir.glob("#{input}*").sort
    opts.map! { |o| o.gsub " ", "\\ " } if Reline.completion_quote_character.nil?
    opts
  end

  # Reline.completion_append_character = " "
  Reline.completer_quote_characters = "\"'"

  # Reline.auto_indent_proc = -> _lines, line, _column, _check_new_auto_indent do
  #   # puts "lines: #{lines}"
  #   # puts "line: #{line}"
  #   # puts "column: #{column}"
  #   # puts "check_new_auto_indent: #{check_new_auto_indent}"
  #   line * 2
  # end

  # Reline.output_modifier_proc = -> output, complete: do
  #   Msh::Readline::SyntaxHighlighter.new(output).code
  # end
end


