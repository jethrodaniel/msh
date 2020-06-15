# frozen_string_literal: true

require "reline" unless RUBY_ENGINE == "mruby"

module Msh
  module Readline
    def self.readline prompt, keep_history = true
      if Object.const_defined? :Reline
        ::Reline.readline(prompt, keep_history)
      else
        print prompt
        gets&.chomp
      end
    end

    def self.add_to_history line
      return if ENV["NO_READLINE"] || RUBY_ENGINE == "mruby"

      # don't add blank lines or duplicates to history
      return unless /\A\s+\z/ =~ line || ::Reline::HISTORY.to_a.dig(-2) == line

      ::Reline::HISTORY.pop
    end
  end
end
