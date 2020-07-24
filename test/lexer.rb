def it_lexes code, tokens
  assert code do
    expected = Msh::Lexer.new(code).tokens.map(&:to_s)
    assert_equal expected, tokens
  end
end

assert "basics" do
  it_lexes "echo hi", [
    '[1:1-4][WORD, "echo"]',
    '[1:5-5][SPACE, " "]',
    '[1:6-7][WORD, "hi"]',
    '[1:8-8][EOF, "\\u0000"]'
  ]
  it_lexes "cd ..", [
    '[1:1-2][WORD, "cd"]',
    '[1:3-3][SPACE, " "]',
    '[1:4-5][WORD, ".."]',
    '[1:6-6][EOF, "\\u0000"]'
  ]
  it_lexes "...", [
    '[1:1-3][WORD, "..."]',
    '[1:4-4][EOF, "\\u0000"]'
  ]
end
