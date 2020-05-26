#!/usr/bin/env ruby
# frozen_string_literal: true

def __main__ _argv
  puts "a"
  puts RUBY_ENGINE
  puts "b"

  require "./lib/msh/version"
  require "./lib/msh/lexer"

  puts "msh #{Msh::VERSION}"
  puts Msh::Lexer.new("echo")

  puts "bye"
end
