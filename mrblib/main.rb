# frozen_string_literal: true

module Kernel
  def warn msg
    $stderr.puts msg # rubocop:disable Style/StderrPuts
  end

  def abort msg
    warn msg
    exit(1)
  end
end

dir = File.dirname(File.realpath(__FILE__)) # rubocop:disable Style/Dir

$: << File.join(dir, "../lib") # rubocop:disable Style/SpecialGlobalVars

require "msh/version"
require "msh/lexer"
require "msh/parser"
require "msh/interpreter"

def __main__ _argv
  # Msh::Lexer.start
  # Msh::Parser.start
  Msh.start
end

__main__(ARGV) unless RUBY_ENGINE == "mruby"
