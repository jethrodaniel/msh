# frozen_string_literal: true

require "msh/lexer"

describe Msh::Lexer do
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
