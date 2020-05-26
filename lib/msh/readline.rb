# frozen_string_literal: true

begin
  require "reline"
rescue LoadError => e
  puts e
end

module Msh
  module Readline
    def self.readline prompt, keep_history
      if defined? Reline
        Reline.readline(prompt, keep_history)
      else
        gets.chomp
      end
    end
  end
end
