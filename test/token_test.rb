# frozen_string_literal: true

def t type, value, line, column
  Msh::Token.new :type => type, :value => value, :line => line, :column => column
end

class Msh::Token
  def match? *types
    types.include? type
  end
end

assert "wtf" do
  a = t :REDIRECT_OUT, ">", 1, 2
  assert_true a.match?(*Msh::Parser::REDIRECTS)
  assert_false a.match?(*Msh::Parser::WORDS)
end
