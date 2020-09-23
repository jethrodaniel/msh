require "msh/interpreter"

describe Msh::Interpreter do
  subject { Msh::Interpreter.new }

  it "#process" do
    ast = s(:EXPR, s(:CMD, s(:WORD, s(:LIT, "echo"))))
    out = subject.process(ast)
    expect(out).to be_zero

    ast = s(:EXPR, s(:CMD, s(:WORD, s(:LIT, "notarealcommand"))))
    out = subject.process(ast)
    expect(out).to_not be_zero
  end

  it "#interpret" do
    out = subject.interpret "echo"
    expect(out).to be_zero

    out = subject.interpret "notarealcommand"
    expect(out).to_not be_zero
  end

  describe "builtins" do
    # https://unix.stackexchange.com/a/79895/354783
    it "forks if part of a pipeline" do
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
      expect(out).to eq(<<~'OUT')
        /tmp
        hi
        /tmp
        /
      OUT
      expect(err).to eq("")
    end

    describe "help" do
      it "shows `msh` when called with no args" do
        man = File.read(Msh.root + "spec/fixtures/help/msh.txt")
        expect(sh("MANPAGER=cat bundle exec #{__dir__}/../../exe/msh -c help")).to eq(man)
      end

      it "has tab completion" do
        skip
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
          skip
          man = File.read(Msh.root + "spec/fixtures/help/#{topic}.txt")
          expect(sh("MANPAGER=cat msh -c 'help #{topic}'")).to eq(man)
        end
      end
    end

    describe "q[uit]" do
      it "quits the shell" do
        skip
      end
    end

    describe "hist[ory]" do
      context "when interactive" do
        it "shows shell history" do
          skip "intermittent failures on CI (TODO: fix this)" if ENV["CI"]

          # PTY.spawn("msh") do |read, write, _pid|
          #   read.expect(/interpreter> /, 1) do |msg|
          #     expect(msg).to eq(["interpreter> "])
          #   end

          #   write.puts "hist"
          #   read.expect("1 hist", 1) do |msg|
          #     expect(msg).to eq(["hist\r\n1 hist"])
          #   end

          #   write.puts "echo msh ftw"
          #   read.expect("msh ftw", 3) do |msg|
          #     # expect(msg).to eq(["\r\necho msh ftw"])
          #     expect(msg).to eq(["\r\ninterpreter> echo msh ftw"])
          #   end
          # end
        end
      end
    end
  end
end
