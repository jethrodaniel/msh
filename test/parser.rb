include Msh::AST::Sexp

def it_parses code, ast
  assert code do
    expected = Msh::Parser.new(code).parse
    assert_equal expected, ast
  end
end

# assert "basics" do
#   it_parses "echo hi",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "echo")),
#                   s(:WORD,
#                     s(:LIT, "hi")))))
#   it_parses "cd ..",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "cd")),
#                   s(:WORD,
#                     s(:LIT, "..")))))
#   it_parses "...",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "...")))))
# end
# assert "mutliple commands" do
#   it_parses "echo; echo; echo",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "echo")))),
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "echo")))),
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "echo")))))
# end
# assert "conditionals" do
#   it_parses "echo a && echo b",
#             s(:PROG,
#               s(:EXPR,
#                 s(:AND,
#                   s(:CMD,
#                     s(:WORD,
#                       s(:LIT, "echo")),
#                     s(:WORD,
#                       s(:LIT, "a"))),
#                   s(:CMD,
#                     s(:WORD,
#                       s(:LIT, "echo")),
#                     s(:WORD,
#                       s(:LIT, "b"))))))
#   it_parses "echo a || echo b",
#             s(:PROG,
#               s(:EXPR,
#                 s(:OR,
#                   s(:CMD,
#                     s(:WORD,
#                       s(:LIT, "echo")),
#                     s(:WORD,
#                       s(:LIT, "a"))),
#                   s(:CMD,
#                     s(:WORD,
#                       s(:LIT, "echo")),
#                     s(:WORD,
#                       s(:LIT, "b"))))))
# end
# assert "pipes" do
#   skip
#   it_parses "fortune | cowsay | wc -l",
#             s(:PROG,
#               s(:EXPR,
#                 s(:PIPELINE,
#                   s(:CMD,
#                     s(:WORD,
#                       s(:LIT, "fortune"))),
#                   s(:CMD,
#                     s(:WORD,
#                       s(:LIT, "cowsay"))),
#                   s(:CMD,
#                     s(:WORD,
#                       s(:LIT, "wc")),
#                     s(:WORD,
#                       s(:LIT, "-l"))))))
# end
# assert "|&" do
#   skip
#   # it_parses "fortune |& cowsay",
# end
# assert "redirect output" do
#   skip
#   it_parses ">out",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:REDIRECT,
#                     s(:REDIRECT_OUT, 1, "out")))))
#   it_parses "2>&2",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:REDIRECT, 2, :DUP_OUT_FD))))
#   it_parses "42>out",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:REDIRECT,
#                     s(:REDIRECT_OUT, 42, "out")))))
#   it_parses "&>out",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:REDIRECT,
#                     s(:AND_REDIRECT_RIGHT, 1, "out")))))
# end
# assert "redirect input" do
#   skip
#   it_parses "<in",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:REDIRECT,
#                     s(:REDIRECT_IN, 0, "in")))))
#   it_parses "prog < in > out",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "prog")),
#                   s(:REDIRECT,
#                     s(:REDIRECT_IN, 0, "in")),
#                   s(:REDIRECT,
#                     s(:REDIRECT_OUT, 1, "out")))))
# end
# assert "comments" do
#   skip
#   it_parses "#x", s(:NOOP)
#   it_parses "# look! # a comment!\n\n\n\n", s(:NOOP)
#   it_parses "fortune # comments continue until newlines",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "fortune")))))
# end
# assert "job control" do
#   skip # it_parses "a &"
# end
# assert "newlines" do
#   code = <<-L
# echo hi
# echo newlines
# echo yay
#   L
#   it_parses code,
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "echo")),
#                   s(:WORD,
#                     s(:LIT, "hi")))),
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "echo")),
#                   s(:WORD,
#                     s(:LIT, "newlines")))),
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "echo")),
#                   s(:WORD,
#                     s(:LIT, "yay")))))
# end
# assert "interpolation" do
#   it_parses "echo \#{Math::PI}",
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "echo")),
#                   s(:WORD,
#                     s(:INTERP, "\#{Math::PI}")))))
#   it_parses 'a#{#{:b}#{:c}}d',
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "a"),
#                     s(:INTERP, "\#{\#{:b}\#{:c}}"),
#                     s(:LIT, "d")))))
#   it_parses 'echo a#{:b}c#{:d}e a#{:b} #{:c}d #{1}#{2}',
#             s(:PROG,
#               s(:EXPR,
#                 s(:CMD,
#                   s(:WORD,
#                     s(:LIT, "echo")),
#                   s(:WORD,
#                     s(:LIT, "a"),
#                     s(:INTERP, "\#{:b}"),
#                     s(:LIT, "c"),
#                     s(:INTERP, "\#{:d}"),
#                     s(:LIT, "e")),
#                   s(:WORD,
#                     s(:LIT, "a"),
#                     s(:INTERP, "\#{:b}")),
#                   s(:WORD,
#                     s(:INTERP, "\#{:c}"),
#                     s(:LIT, "d")),
#                   s(:WORD,
#                     s(:INTERP, "\#{1}"),
#                     s(:INTERP, "\#{2}")))))
# end
# assert "if/else" do
#   code = <<-L
# if echo a
#   echo b
# end
#   L
#   skip # it_parses code,
# end
