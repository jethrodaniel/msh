require "spec_helper"
require "msh/ast"

describe Msh::AST do
  include Msh::AST::Sexp

  it "#line, #column" do
    node = s(s(:LIT, "wow"), :line => 1, :column => 2)
    _(node.line).must_equal 1
    _(node.column).must_equal 2
  end
end
