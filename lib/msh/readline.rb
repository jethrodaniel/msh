unless RUBY_ENGINE == "mruby"
  require "reline"

  Reline.completion_proc = -> input do
    Dir.glob("#{input}*").sort
  end

  Reline.completion_append_character = " "
  Reline.completer_quote_characters = "\"'"
end

module Msh
  module Readline
    def self.readline prompt, keep_history = true
      return ::Reline.readline(prompt, keep_history) if Object.const_defined? :Reline

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
