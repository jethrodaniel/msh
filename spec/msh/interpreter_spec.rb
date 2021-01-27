require "spec_helper"
require "msh/interpreter"
require "msh"

describe Msh::Interpreter do
  attr_accessor :subject

  def setup
    @subject = Msh::Interpreter.new
  end

  include Msh::AST::Sexp

  it "#process" do
    ast = s(:EXPR, s(:CMD, s(:WORD, s(:LIT, "echo"))))
    out = subject.process(ast)
    _(out).must_be :zero?

    ast = s(:EXPR, s(:CMD, s(:WORD, s(:LIT, "notarealcommand"))))
    out = subject.process(ast)
    _(out).wont_be :zero?
  end

  it "#interpret" do
    out = subject.interpret "echo"
    _(out).must_be :zero?

    out = subject.interpret "notarealcommand"
    _(out).wont_be :zero?
  end

  describe "builtins" do
    # https://unix.stackexchange.com/a/79895/354783
    it "forks if part of a pipeline" do
      skip
      out, err = capture_subprocess_io do
        subject.interpret <<~MSH
          cd /tmp
          pwd
          cd / | echo hi
          pwd
          cd /
          pwd
        MSH
      end
      _(out).to eq(<<~'OUT')
        /tmp
        hi
        /tmp
        /
      OUT
      _(err).to eq("")
    end

    describe "help" do
      it "shows `msh` when called with no args" do
        man = File.read(File.join(Msh.root, "spec/fixtures/help/msh.txt"))
        _(sh("MANPAGER=cat msh -c help")).must_equal_with_diff man
      end

      it "has tab completion" do
        skip "test with https://github.com/aycabta/yamatanooroti"
      end

      %w[
        cd
        help
        history
        lexer
        parser
        prompt
        repl
      ].each do |topic|
        it topic do
          man = File.read(Msh.root + "spec/fixtures/help/#{topic}.txt")
          skip "need to get in-file manpages for these again, or some kind of dsl"
          _(sh("MANPAGER=cat msh -c 'help #{topic}'")).must_equal_with_diff man
        end
      end
    end

    describe "q[uit]" do
      it "quits the shell" do
        skip
      end
    end

    describe "hist[ory]" do
      describe "when interactive" do
        it "shows shell history" do
          skip "test with https://github.com/aycabta/yamatanooroti"
        end
      end
    end
  end
end
