# frozen_string_literal: true

begin
  require "reline"
rescue LoadError => e
  warn "#{e.class}: #{e.message}"
end

module Msh
  module Readline
    def self.readline prompt, keep_history
      if Object.const_defined? :Reline
        ::Reline.readline(prompt, keep_history)
      else
        print "lexer> "
        gets&.chomp
      end
    end
  end
end
