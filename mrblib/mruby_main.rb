# frozen_string_literal: true

def __main__ _argv
  $: << File.expand_path("lib") # rubocop:disable Style/SpecialGlobalVars

  require "msh/version"
  # require "msh/lexer"

  puts "hi"

  puts "msh v#{Msh::VERSION}"
  # puts "tokens: #{Msh::Lexer.new('echo').tokens}"

  puts "by"
end
