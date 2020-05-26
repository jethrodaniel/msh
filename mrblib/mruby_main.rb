# frozen_string_literal: true

def warn msg
  $stderr.puts msg # rubocop:disable Style/StderrPuts
end

def __main__
  $: << File.expand_path("lib") # rubocop:disable Style/SpecialGlobalVars

  require "msh/version"
  require "msh/lexer"

  puts "msh v#{Msh::VERSION}"

  # Msh::Lexer.start(argv)
  Msh::Lexer.interactive

  puts "BYe"
end
