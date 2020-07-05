# frozen_string_literal: true

require "msh/core_extensions"

require "lex/lex"
require "peg/peg"

if $PROGRAM_NAME == __FILE__

  parser = Peg::Grammar::Parser.new File.read("lib/msh/grammar.peg")

  rules = parser.parse
  puts rules

  gen = Peg::Grammar::Generator.new rules
  puts "-> parser.rb"
  File.open("parser.rb", "w") { |f| gen.generate f }
end
