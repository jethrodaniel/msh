unless RUBY_ENGINE == "mruby"
  require "reline"

  Reline.prompt_proc = -> buffer do
    return [interpreter.prompt] + ["> "] * buffer.size if buffer.size > 1

    [interpreter.prompt]
  end

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

  # Colorize here
  Reline.output_modifier_proc = -> output, complete: do
    # puts "%" if complete
    output
  end
end

module Msh
  module Readline
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

    def self.add_to_history line
      return if ENV["NO_READLINE"] || RUBY_ENGINE == "mruby"

      # don't add blank lines or duplicates to history
      return unless /\A\s+\z/ =~ line || ::Reline::HISTORY.to_a.dig(-2) == line

      ::Reline::HISTORY.pop
    end
  end
end
