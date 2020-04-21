# frozen_string_literal: true

require "msh/parser"

RSpec.describe Msh::Parser do
  subject { Msh::Parser.new }

  let(:ruby_version) { RUBY_VERSION.gsub(/[^\d]/, "")[0..2].to_i * 0.01 }

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
    s(:WORD, "echo"),
    s(:WORD, "such"),
    s(:WORD, "wow")))
~
  code = %q~echo such wow~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
    s(:WORD, "echo"),
    s(:WORD, "so"),
    s(:WORD, "scare")))
~
  code = %q~echo so scare~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
    s(:WORD, "/usr/bin/program\\ with\\ space"),
    s(:WORD, "\\but\\ this\\ is\\ an\\ arg")))
~
  code = %q~/usr/bin/program\ with\ space \but\ this\ is\ an\ arg~

  it code do
    skip

    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~~
  code = %q~a&&b~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
    s(:WORD, "/usr/bin/program\\ with\\ space"),
    s(:WORD, "\\but\\ this\\ is\\ an\\ arg")))
~
  code = %q~echo a\;b~

  it code do
    skip

    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~~
  code = %q~find . -name "*.rb" -exec sed -i 's/msh/yas/g' {} \;)~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
    s(:WORD, "cd"),
    s(:WORD, "..")))
~
  code = %q~cd ..~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
    s(:WORD, "...")))
~
  code = %q~...~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:PIPELINE,
    s(:COMMAND,
      s(:WORD, "fortune")),
    s(:COMMAND,
      s(:WORD, "cowsay"))))
~
  code = %q~fortune | cowsay~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:PIPELINE,
    s(:COMMAND,
      s(:WORD, "fortune"),
      s(:REDIRECTIONS,
        s(:DUP, 2, 1))),
    s(:COMMAND,
      s(:WORD, "cowsay"))))
~
  code = %q~fortune |& cowsay~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:PIPELINE,
    s(:COMMAND,
      s(:WORD, "fortune"),
        s(:REDIRECTIONS,
          s(:REDIRECT, 1, "out"),
          s(:DUP, 2, 1))),
    s(:COMMAND,
      s(:WORD, "cowsay"))))
~
  code = %q~fortune >out |& cowsay~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:PIPELINE,
    s(:COMMAND,
      s(:WORD, "fortune"),
      s(:REDIRECTIONS,
        s(:REDIRECT, 1, "out"))),
    s(:COMMAND,
      s(:WORD, "wow"),
      s(:REDIRECTIONS,
        s(:DUP, 2, 1))),
    s(:COMMAND,
      s(:WORD, "cowsay"))))
~
  code = %q~fortune >out | wow |& cowsay~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:PIPELINE,
    s(:COMMAND,
      s(:WORD, "fortune"),
      s(:REDIRECTIONS,
        s(:REDIRECT, 1, "out"))),
    s(:COMMAND,
      s(:WORD, "wow"),
      s(:REDIRECTIONS,
        s(:DUP, 2, 1))),
    s(:COMMAND,
      s(:WORD, "cowsay")),
    s(:COMMAND,
      s(:WORD, "wow"))))
~
  code = %q~fortune >out | wow |& cowsay | wow~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:PIPELINE,
    s(:COMMAND,
      s(:WORD, "a"),
      s(:REDIRECTIONS,
        s(:REDIRECT, 1, "out"))),
    s(:COMMAND,
      s(:WORD, "b"),
      s(:REDIRECTIONS,
        s(:REDIRECT, 0, "in"),
        s(:REDIRECT, 1, "out"),
        s(:DUP, 2, 1))),
    s(:COMMAND,
      s(:WORD, "c"),
      s(:REDIRECTIONS,
        s(:DUP, 2, 1))),
    s(:COMMAND,
      s(:WORD, "d"))))
~
  code = %q~a >out | b <in >out |& c |& d~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:NEG_PIPELINE,
    s(:COMMAND,
      s(:WORD, "fortune")),
    s(:COMMAND,
      s(:WORD, "cowsay"))))
~
  code = %q~! fortune | cowsay~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:PIPELINE,
    s(:TIME),
    s(:WORD, "echo")))
~
  code = %q~time echo~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:PIPELINE,
    s(:TIME_P),
    s(:WORD, "echo")))
~
  code = %q~time -p echo~

  it code do
    skip

    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
   s(:WORD, "echo"),
   s(:WORD, "time")))
~
  code = %q~echo time~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:NEG_PIPELINE,
    s(:TIME),
    s(:COMMAND,
      s(:WORD, "fortune")),
    s(:COMMAND,
      s(:WORD, "cowsay"))))
~
  code = %q~time ! fortune | cowsay~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:NEG_PIPELINE,
    s(:TIME_P),
    s(:COMMAND,
      s(:WORD, "fortune")),
    s(:COMMAND,
      s(:WORD, "cowsay"))))
~
  code = %q~time -p ! fortune | cowsay~

  it code do
    skip

    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:PIPELINE,
    s(:COMMAND,
      s(:WORD, "a")),
    s(:COMMAND,
      s(:WORD, "b")),
    s(:COMMAND,
      s(:WORD, "c"))))
~
  code = %q~a | b | c~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:OR,
    s(:COMMAND,
      s(:WORD, "a")),
    s(:COMMAND,
      s(:WORD, "b"))))
~
  code = %q~a || b~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:AND,
    s(:COMMAND,
      s(:WORD, "a")),
    s(:COMMAND,
      s(:WORD, "b"))))
~
  code = %q~a && b~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:AND,
    s(:COMMAND,
      s(:WORD, "date")),
    s(:PIPELINE,
      s(:COMMAND,
        s(:WORD, "date")),
      s(:COMMAND,
        s(:WORD, "cowsay")))))
~
  code = %q~date && date | cowsay~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:GROUP,
    s(:COMMAND,
      s(:WORD, "a"))))
~
  code = %q~{a}~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:PIPELINE,
    s(:GROUP,
      s(:LIST,
        s(:COMMAND,
          s(:WORD, "a")),
        s(:COMMAND,
          s(:WORD, "b"))),
      s(:REDIRECTIONS,
        s(:REDIRECT, 1, "out"))),
    s(:COMMAND,
      s(:WORD, "c"))))
~
  code = %q~{a;b}>out|c~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:SUBSHELL,
    s(:COMMAND,
      s(:WORD, "a"))))
~
  code = %q~(a)~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:PIPELINE,
    s(:SUBSHELL,
      s(:LIST,
        s(:COMMAND,
          s(:WORD, "a")),
        s(:COMMAND,
          s(:WORD, "b"))),
      s(:REDIRECTIONS,
        s(:REDIRECT, 1, "out"))),
    s(:COMMAND,
      s(:WORD, "c"))))
~
  code = %q~(a;b)>out|c~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:LIST,
    s(:AND,
      s(:PIPELINE,
        s(:GROUP,
          s(:COMMAND,
            s(:WORD, "a"))),
        s(:SUBSHELL,
          s(:COMMAND,
            s(:WORD, "b")),
          s(:REDIRECTIONS,
            s(:REDIRECT, 1, "out")))),
      s(:OR,
        s(:COMMAND,
          s(:WORD, "c")),
        s(:COMMAND,
          s(:WORD, "d"),
          s(:REDIRECTIONS,
            s(:REDIRECT, 1, "t"))))),
    s(:COMMAND,
      s(:WORD, "a")),
    s(:GROUP,
      s(:LIST,
        s(:COMMAND,
          s(:WORD, "b")),
        s(:COMMAND,
          s(:WORD, "c"))),
      s(:REDIRECTIONS,
        s(:REDIRECT, 1, "wow")))))
~
  code = %q~{a}|(b)>out&&c||d>t;a;{b;c}>wow~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:GROUP,
    s(:COMMAND,
      s(:WORD, "a"))))
~
  code = %q~{a || b}~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~~
  code = %q~2>out 1 4>out~

  it code do
    skip

    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
    s(:WORD, "ls"),
    s(:WORD, "a"),
    s(:REDIRECTIONS,
      s(:REDIRECT, 0, "in"),
      s(:REDIRECT, 1, "in"),
      s(:REDIRECT, 1, "out"),
      s(:REDIRECT, 2, "out"),
      s(:APPEND, 1, "foo"),
      s(:REDIRECT_NOCLOBBER, 1, "wow"),
      s(:REDIRECT, 3, "ouch"),
      s(:REDIRECT_BOTH, "un"),
      s(:APPEND_BOTH, "mas"),
      s(:DUP, 4, 1),
      s(:DUP, 0, 4),
      s(:REDIRECT_BOTH, "5"),
      s(:DUP, 2, 1),
      s(:MOVE_FD, 13, 2),
      s(:OPEN_RW, 6, "foo"))))
~
  code = %q~ls a <in 1<in >out 2>out >>foo >|wow 3>|ouch &>un &>>mas 4<&1 <&4 >&5 2>&1 13>&2- 6<>foo~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:NOOP)
~
  code = %q~#~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:NOOP)
~
  code = %q~#x~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:NOOP)
~
  code = %q~# look! # a comment!



~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
    s(:WORD, "fortune")))
~
  code = %q~fortune # comments continue until one or more newlines~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~~
  code = %q~a &~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:LIST,
    s(:PIPELINE,
      s(:COMMAND,
        s(:WORD, "ls")),
      s(:COMMAND,
        s(:WORD, "wow"),
        s(:REDIRECTIONS,
          s(:REDIRECT, 3, "doggo"),
          s(:DUP, 2, 1),
          s(:REDIRECT, 1, "/dev/null")))),
    s(:AND,
      s(:COMMAND,
        s(:WORD, "wow")),
      s(:OR,
        s(:COMMAND,
          s(:WORD, "wow")),
        s(:AND,
          s(:COMMAND,
            s(:WORD, "o"),
            s(:REDIRECTIONS,
              s(:REDIRECT, 1, "out"))),
          s(:PIPELINE,
            s(:COMMAND,
              s(:WORD, "goose"),
              s(:REDIRECTIONS,
                s(:DUP, 2, 1))),
            s(:COMMAND,
              s(:WORD, "duck"))))))))
~
  code = %q~ls|wow 3>doggo 2>&1 >/dev/null;wow&&wow||o>out&&goose|&duck~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
    s(:WORD, "ls")),
  s(:COMMAND,
    s(:WORD, "wow"),
    s(:WORD, "newlines")),
  s(:COMMAND,
    s(:WORD, "yay")))
~
  code = %q~ls
wow newlines
yay
~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~~
  code = %q~a#{#{:b}#{:c}}d~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
    s(:WORD, "echo"),
    s(:INTERPOLATION, ":a"),
    s(:INTERPOLATION, ":b")))
~
  code = %q~echo #{:a} #{:b}~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end

  code = "\n#{code}\n"
  source = "\n#{source}\n"

  source = %q~s(:EXPR,
  s(:COMMAND,
    s(:WORD, "echo"),
    s(:WORD,
      s(:LITERAL, "a"),
      s(:INTERPOLATION, ":b"),
      s(:LITERAL, "c"),
      s(:INTERPOLATION, ":d"),
      s(:LITERAL, "e")),
    s(:WORD,
      s(:LITERAL, "a"),
      s(:INTERPOLATION, ":b")),
    s(:WORD,
      s(:INTERPOLATION, ":c"),
      s(:LITERAL, "d")),
    s(:WORD,
      s(:INTERPOLATION, "1"),
      s(:INTERPOLATION, "2"))))
~
  code = %q~echo a#{:b}c#{:d}e a#{:b} #{:c}d #{1}#{2}~

  it code do
    ast = if ruby_version < 2.6
            binding.eval(source, __FILE__, __LINE__)
          else
            binding.eval(source, *binding.source_location)
           end

    lexer = Msh::Lexer.new code
    parser = Msh::Parser.new lexer.tokens
    expect(parser.parse).to eq ast
  end
end

# # **note**: testing a private method here
# describe "#expand_PIPE_AND" do
#   it ":COMMAND |& :COMMAND" do
#     a = s(:COMMAND, s(:WORD, "foo"))
#     b = s(:COMMAND, s(:WORD, "bar"))
#     p = Msh::Parser.new.send :expand_PIPE_AND, :left => a, :right => b

#     expect(p).to eq \
#       s(:PIPELINE,
#         s(:COMMAND,
#           s(:WORD, "foo"),
#           s(:REDIRECTIONS,
#             s(:DUP, 2, 1))),
#         s(:COMMAND,
#           s(:WORD, "bar")))
#   end

#   it ":COMMAND <redirections> |& :COMMAND" do
#     a = s(:COMMAND, s(:WORD, "foo"), s(:REDIRECTIONS, s(:DUP, 3, 4)))
#     b = s(:COMMAND, s(:WORD, "bar"))
#     p = Msh::Parser.new.send :expand_PIPE_AND, :left => a, :right => b

#     expect(p).to eq \
#       s(:PIPELINE,
#         s(:COMMAND,
#           s(:WORD, "foo"),
#           s(:REDIRECTIONS,
#             s(:DUP, 3, 4),
#             s(:DUP, 2, 1))),
#         s(:COMMAND,
#           s(:WORD, "bar")))
#   end
# end
# end
#

#  # Run each input and test it's output for a failure
#  #
#  #   "bad msh code" => [ErrorType, "error message"]
#  {
#    # ">" => [
#    #   Msh::Parser::Error,
#    #   /\[\d\]\[\d\]: parse error on value/
#    #   # %([1][2]: parse error on value ">" (error))
#    # ]
#  }.each do |code, (error_class, error_msg)|
#    it code.to_s do
#      expect { subject.parse(code) }.to raise_error(error_class, error_msg)
#    end
#  end
