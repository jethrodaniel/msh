# frozen_string_literal: true

require "msh/lexer"

# LEX_DATA = {
#  "git c -m 'update readme'" => [
#    [:WORD, "git"],
#    [:WORD, "c"],
#    [:WORD, "-m"],
#    [:SINGLE_QUOTE_STR, "update readme"]
#  ],
#  'echo "#{Time.now}"' => [
#    [:WORD, "echo"],
#    [:DOUBLE_QUOTE_STR, '#{Time.now}']
#  ],

#  #
#  # globs, wildcards, etc
#  #
#  "ls *.c" => [
#    [:WORD, "ls"],
#    [:GLOB, "*"],
#    [:WORD, ".c"]
#  ],
#  "ls foo.?" => [
#    [:WORD, "ls"],
#    [:WORD, "foo."],
#    [:QUESTION, "?"]
#  ],

#  #
#  # newlines, continuation, etc
#  #
#  "\n" => [
#    [:NEWLINE, "\n"]
#  ],

#  #
#  # redirection
#  #
#  "tail file > tail.log" => [
#    [:WORD, "tail"],
#    [:WORD, "file"],
#    [:REDIRECT_RIGHT, ">"],
#    [:WORD, "tail.log"]
#  ],
#  "tail -n100 log >> tail.log" => [
#    [:WORD, "tail"],
#    [:WORD, "-n100"],
#    [:WORD, "log"],
#    [:DOUBLE_REDIRECT_RIGHT, ">>"],
#    [:WORD, "tail.log"]
#  ],
#  "psql -Uuser -d db< file.sql" => [
#    [:WORD, "psql"],
#    [:WORD, "-Uuser"],
#    [:WORD, "-d"],
#    [:WORD, "db"],
#    [:REDIRECT_LEFT, "<"],
#    [:WORD, "file.sql"]
#  ],
#  "a 1> 2>&1 3<&2 3>out" => [
#    [:WORD, "a"],
#    [:REDIRECT_RIGHT, "1>"],
#    [:REDIRECT_INTO, "2>&1"],
#    [:REDIRECT_FROM, "3<&2"],
#    [:REDIRECT_RIGHT, "3>"],
#    [:WORD, "out"]
#  ],
#  "foo <input >output" => [
#    [:WORD, "foo"],
#    [:REDIRECT_LEFT, "<"],
#    [:WORD, "input"],
#    [:REDIRECT_RIGHT, ">"],
#    [:WORD, "output"]
#  ]

# }.freeze

# RSpec.describe Msh::Lexer do
#   subject { Msh::Lexer.new }

#   LEX_DATA.each do |code, tokens|
#     it code.to_s do
#       expect(subject.tokenize(code)).to eq tokens
#     end
#   end
# end

RSpec.describe Msh::Lexer do
  let(:ruby_version) { RUBY_VERSION.gsub(/[^\d]/, "")[0..2].to_i * 0.01 }

  Examples.each do |code, data|
    # don't interpolate the token string
    source = data[:tokens].gsub '#{', '\#{' # yeah, this is stupid

    it code do
      skip unless data[:lexer_valid]

      expected = binding.eval(source, *binding.source_location)
      tokens = Msh::Lexer.new(code).tokens.map(&:to_s)

      expect(tokens).to eq expected
    end
  end

  describe "incremental lexing" do
    def t type, value, line, column
      Msh::Token.new :type => type,
                     :value => value,
                     :line => line,
                     :column => column
    end

    it "lexes one token at a time" do
      lex = Msh::Lexer.new "fortune | cowsay\n"

      expect(lex.next?).to be true
      expect(lex.current_token).to be nil

      expect(lex.next_token).to eq t(:WORD, "fortune", 1, 1)
      expect(lex.next_token).to eq t(:SPACE, " ", 1, 8)
      expect(lex.next_token).to eq t(:PIPE, "|", 1, 9)
      expect(lex.next_token).to eq t(:SPACE, " ", 1, 10)
      expect(lex.next_token).to eq t(:WORD, "cowsay", 1, 11)
      expect(lex.next_token).to eq t(:NEWLINE, "\n", 1, 17)
      expect(lex.next?).to be true
      expect(lex.next_token).to eq t(:EOF, "\u0000", 2, 1)
      expect(lex.next?).to be false

      # err = "error at line 2, column 2: out of input"
      # expect do
      #   lex.next_token
      # end.to raise_error(Msh::Lexer::Error, err)
    end
  end
end
