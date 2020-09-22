require_relative "../init"
require_relative "../helpers/ast"

context Msh::AST do
  test "#line, #column" do
    node = Msh::AST::Node.new :WORD, s(:LIT, "wow"), :line => 1, :column => 2
    assert(node.line == 1)
    assert(node.column == 2)
  end
end
