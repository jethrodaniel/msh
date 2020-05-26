# frozen_string_literal: true

def warn msg
  $stderr.puts msg # rubocop:disable Style/StderrPuts
end

def __main__
  $: << File.expand_path("lib") # rubocop:disable Style/SpecialGlobalVars

  require "msh/version"
  require "msh/lexer"

  Msh::Lexer.start

  puts "BYe"
end
