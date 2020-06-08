# frozen_string_literal: true

require "msh/lexer"

def it_lexes code, tokens
  assert code do
    expected = Msh::Lexer.new(code).tokens.map(&:to_s)
    assert_equal expected, tokens
  end
end

# describe Msh::Lexer do
#   # @todo smaller test here
#   describe "incremental lexing" do
#     def t type, value, line, column
#       Msh::Token.new :type => type,
#                      :value => value,
#                      :line => line,
#                      :column => column
#     end

#     it "lexes one token at a time" do
#       lex = Msh::Lexer.new "fortune | cowsay\n"

#       expect(lex.next?).to be true
#       expect(lex.current_token).to be nil

#       expect(lex.next_token).to eq t(:WORD, "fortune", 1, 1)
#       expect(lex.next_token).to eq t(:SPACE, " ", 1, 8)
#       expect(lex.next_token).to eq t(:PIPE, "|", 1, 9)
#       expect(lex.next_token).to eq t(:SPACE, " ", 1, 10)
#       expect(lex.next_token).to eq t(:WORD, "cowsay", 1, 11)
#       expect(lex.next_token).to eq t(:NEWLINE, "\n", 1, 17)
#       expect(lex.next?).to be true
#       expect(lex.next_token).to eq t(:EOF, "\u0000", 2, 1)
#       expect(lex.next?).to be false

#       # err = "error at line 2, column 2: out of input"
#       # expect do
#       #   lex.next_token
#       # end.to raise_error(Msh::Lexer::Error, err)
#     end
#   end
# end

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

assert "mutliple commands" do
  it_lexes "echo; echo; echo", [
    '[1:1-4][WORD, "echo"]',
    '[1:5-5][SEMI, ";"]',
    '[1:6-6][SPACE, " "]',
    '[1:7-10][WORD, "echo"]',
    '[1:11-11][SEMI, ";"]',
    '[1:12-12][SPACE, " "]',
    '[1:13-16][WORD, "echo"]',
    '[1:17-17][EOF, "\u0000"]'
  ]
end

assert "conditionals" do
  it_lexes "echo a && echo b", [
    '[1:1-4][WORD, "echo"]',
    '[1:5-5][SPACE, " "]',
    '[1:6-6][WORD, "a"]',
    '[1:7-7][SPACE, " "]',
    '[1:8-9][AND, "&&"]',
    '[1:10-10][SPACE, " "]',
    '[1:11-14][WORD, "echo"]',
    '[1:15-15][SPACE, " "]',
    '[1:16-16][WORD, "b"]',
    '[1:17-17][EOF, "\u0000"]'
  ]
  it_lexes "echo a || echo b", [
    '[1:1-4][WORD, "echo"]',
    '[1:5-5][SPACE, " "]',
    '[1:6-6][WORD, "a"]',
    '[1:7-7][SPACE, " "]',
    '[1:8-9][OR, "||"]',
    '[1:10-10][SPACE, " "]',
    '[1:11-14][WORD, "echo"]',
    '[1:15-15][SPACE, " "]',
    '[1:16-16][WORD, "b"]',
    '[1:17-17][EOF, "\u0000"]'
  ]
end
assert "pipes" do
  it_lexes "fortune | cowsay | wc -l", [
    '[1:1-7][WORD, "fortune"]',
    '[1:8-8][SPACE, " "]',
    '[1:9-9][PIPE, "|"]',
    '[1:10-10][SPACE, " "]',
    '[1:11-16][WORD, "cowsay"]',
    '[1:17-17][SPACE, " "]',
    '[1:18-18][PIPE, "|"]',
    '[1:19-19][SPACE, " "]',
    '[1:20-21][WORD, "wc"]',
    '[1:22-22][SPACE, " "]',
    '[1:23-24][WORD, "-l"]',
    '[1:25-25][EOF, "\u0000"]'

  ]
  assert "|&" do
    it_lexes "fortune |& cowsay", [
      '[1:1-7][WORD, "fortune"]',
      '[1:8-8][SPACE, " "]',
      '[1:9-10][PIPE_AND, "|&"]',
      '[1:11-11][SPACE, " "]',
      '[1:12-17][WORD, "cowsay"]',
      '[1:18-18][EOF, "\\u0000"]'
    ]
  end
end
assert "redirections" do
  assert "redirect output" do
    it_lexes ">out", [
      '[1:1-1][REDIRECT_OUT, ">"]',
      '[1:2-4][WORD, "out"]',
      '[1:5-5][EOF, "\u0000"]'
    ]
    it_lexes "2>&2", [
      '[1:1-4][DUP_OUT_FD, "2>&2"]',
      '[1:5-5][EOF, "\u0000"]'
    ]
    it_lexes "42>out", [
      '[1:1-3][REDIRECT_OUT, "42>"]',
      '[1:4-6][WORD, "out"]',
      '[1:7-7][EOF, "\u0000"]'
    ]
    it_lexes "&>out", [
      '[1:1-2][AND_REDIRECT_RIGHT, "&>"]',
      '[1:3-5][WORD, "out"]',
      '[1:6-6][EOF, "\u0000"]'
    ]
  end
  assert "redirect input" do
    it_lexes "<in", [
      '[1:1-1][REDIRECT_IN, "<"]',
      '[1:2-3][WORD, "in"]',
      '[1:4-4][EOF, "\u0000"]'
    ]
  end
  it_lexes "prog < in > out", [
    '[1:1-4][WORD, "prog"]',
    '[1:5-5][SPACE, " "]',
    '[1:6-6][REDIRECT_IN, "<"]',
    '[1:7-7][SPACE, " "]',
    '[1:8-9][WORD, "in"]',
    '[1:10-10][SPACE, " "]',
    '[1:11-11][REDIRECT_OUT, ">"]',
    '[1:12-12][SPACE, " "]',
    '[1:13-15][WORD, "out"]',
    '[1:16-16][EOF, "\u0000"]'
  ]
end
assert "comments" do
  it_lexes "#x", [
    '[1:1-2][COMMENT, "#x"]',
    '[1:3-3][EOF, "\\u0000"]'
  ]
  it_lexes "# look! # a comment!\n\n\n\n", [
    '[1:1-20][COMMENT, "# look! # a comment!"]',
    '[1:21-21][NEWLINE, "\n"]',
    '[2:1-1][NEWLINE, "\n"]',
    '[3:1-1][NEWLINE, "\n"]',
    '[4:1-1][NEWLINE, "\n"]',
    '[5:1-1][EOF, "\u0000"]'
  ]
  it_lexes "fortune # comments continue until one or more newlines", [
    '[1:1-7][WORD, "fortune"]',
    '[1:8-8][SPACE, " "]',
    '[1:9-54][COMMENT, "# comments continue until one or more newlines"]',
    '[1:55-55][EOF, "\u0000"]'
  ]
end
assert "job control" do
  it_lexes "a &", [
    '[1:1-1][WORD, "a"]',
    '[1:2-2][SPACE, " "]',
    '[1:3-3][BG, "&"]',
    '[1:4-4][EOF, "\u0000"]'
  ]
end
assert "newlines" do
  code = <<-L
echo hi
echo newlines
echo yay
  L
  it_lexes code, [
    '[1:1-4][WORD, "echo"]',
    '[1:5-5][SPACE, " "]',
    '[1:6-7][WORD, "hi"]',
    '[1:8-8][NEWLINE, "\n"]',
    '[2:1-4][WORD, "echo"]',
    '[2:5-5][SPACE, " "]',
    '[2:6-13][WORD, "newlines"]',
    '[2:14-14][NEWLINE, "\n"]',
    '[3:1-4][WORD, "echo"]',
    '[3:5-5][SPACE, " "]',
    '[3:6-8][WORD, "yay"]',
    '[3:9-9][NEWLINE, "\n"]',
    '[4:1-1][EOF, "\u0000"]'
  ]
end
assert "interpolation" do
  it_lexes "echo \#{Math::PI}", [
    '[1:1-4][WORD, "echo"]',
    '[1:5-5][SPACE, " "]',
    '[1:6-16][INTERP, "\#{Math::PI}"]',
    '[1:17-17][EOF, "\u0000"]'
  ]
  it_lexes 'a#{#{:b}#{:c}}d', [
    '[1:1-1][WORD, "a"]',
    '[1:2-14][INTERP, "\#{\#{:b}\#{:c}}"]',
    '[1:15-15][WORD, "d"]',
    '[1:16-16][EOF, "\u0000"]'
  ]
  it_lexes 'echo a#{:b}c#{:d}e a#{:b} #{:c}d #{1}#{2}', [
    '[1:1-4][WORD, "echo"]',
    '[1:5-5][SPACE, " "]',
    '[1:6-6][WORD, "a"]',
    '[1:7-11][INTERP, "\#{:b}"]',
    '[1:12-12][WORD, "c"]',
    '[1:13-17][INTERP, "\#{:d}"]',
    '[1:18-18][WORD, "e"]',
    '[1:19-19][SPACE, " "]',
    '[1:20-20][WORD, "a"]',
    '[1:21-25][INTERP, "\#{:b}"]',
    '[1:26-26][SPACE, " "]',
    '[1:27-31][INTERP, "\#{:c}"]',
    '[1:32-32][WORD, "d"]',
    '[1:33-33][SPACE, " "]',
    '[1:34-37][INTERP, "\#{1}"]',
    '[1:38-41][INTERP, "\#{2}"]',
    '[1:42-42][EOF, "\u0000"]'
  ]
end
assert "if/else" do
  code = <<-L
if echo a
  echo b
end
  L
  it_lexes code, [
    '[1:1-2][IF, "if"]',
    '[1:3-3][SPACE, " "]',
    '[1:4-7][WORD, "echo"]',
    '[1:8-8][SPACE, " "]',
    '[1:9-9][WORD, "a"]',
    '[1:10-10][NEWLINE, "\n"]',
    '[2:1-2][SPACE, "  "]',
    '[2:3-6][WORD, "echo"]',
    '[2:7-7][SPACE, " "]',
    '[2:8-8][WORD, "b"]',
    '[2:9-9][NEWLINE, "\n"]',
    '[3:1-3][WORD, "end"]',
    '[3:4-4][NEWLINE, "\n"]',
    '[4:1-1][EOF, "\u0000"]'
  ]
end
