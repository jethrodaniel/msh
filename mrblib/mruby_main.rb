# frozen_string_literal: true

def __main__ _argv
  require "./lib/msh/version"
  # require "./lib/msh/lexer"

  puts "msh v#{Msh::VERSION}"
  # puts Msh::Lexer.new("echo")

  puts "bye"
end
