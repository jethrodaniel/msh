include Msh::AST::Sexp

def it_parses code, ast
  assert code do
    expected = Msh::Parser.new(code).parse
    assert_equal expected, ast
  end
end

assert "basics" do
  it_parses "echo hi",
            s(:PROG,
              s(:EXPR,
                s(:CMD,
                  s(:WORD,
                    s(:LIT, "echo")),
                  s(:WORD,
                    s(:LIT, "hi")))))
  it_parses "cd ..",
            s(:PROG,
              s(:EXPR,
                s(:CMD,
                  s(:WORD,
                    s(:LIT, "cd")),
                  s(:WORD,
                    s(:LIT, "..")))))
  it_parses "...",
            s(:PROG,
              s(:EXPR,
                s(:CMD,
                  s(:WORD,
                    s(:LIT, "...")))))
end
