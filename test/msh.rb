# frozen_string_literal: true

require "msh"

def it_lexes code, tokens
  expected = Msh::Lexer.new(code).tokens.map(&:to_s)
  assert_equal tokens, expected
end

assert "Msh" do
  assert_equal "0.2.0", Msh::VERSION
end

assert "Msh::Lexer" do
  it_lexes "echo hi", [
    '[1:1-4][WORD, "echo"]',
    '[1:5-5][SPACE, " "]',
    '[1:6-7][WORD, "hi"]',
    '[1:8-8][EOF, "\\x00"]'
  ]
end
