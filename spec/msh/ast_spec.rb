# frozen_string_literal: true

require "msh/ast"

RSpec.describe Msh::AST do
  subject do
    Msh::AST::Node.new :WORD, s(:LIT, "wow"), :line => 1, :column => 2
  end

  it "#line, #column" do
    expect(subject.line).to eq 1
    expect(subject.column).to eq 2
  end
end
