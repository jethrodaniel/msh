# frozen_string_literal: true

RSpec.describe Msh::Interpreter do
  subject { Msh::Interpreter.new }

  # Examples.passing.take(1).each do |code, data|
  #   it code do
  #     ast = binding.eval(data[:ast], *binding.source_location)
  #     out = subject.process(ast)

  #     expect(out.existatus).to eq 1
  #   end
  # end

  it ".process" do
    ast = s(:EXPR, s(:COMMAND, s(:WORD, "echo")))
    out = subject.process(ast)
    expect(out.exitstatus).to be_zero

    # ast = s(:EXPR, s(:COMMAND, s(:WORD, "notarealcommand")))
    # out = subject.process(ast)
    # expect(out.exitstatus).to_not be_zero
  end

  describe "builtins" do
    describe "help" do
      it "shows `msh` when called with no args" do
        man = File.read(Msh.root + "spec/fixtures/help/msh.txt")
        expect(sh("MANPAGER=cat msh -c help")).to eq(man)
      end

      it "has tab completion" do
        skip
      end

      Msh.help_topics.each do |topic|
        it topic do
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
          PTY.spawn("msh") do |read, write, _pid|
            read.expect(/interpreter> /, 1) do |msg|
              expect(msg).to eq(["interpreter> "])
            end

            write.puts "hist"
            read.expect("1 hist", 1) do |msg|
              expect(msg).to eq(["hist\r\n1 hist"])
            end

            write.puts "echo msh ftw"
            read.expect("msh ftw", 3) do |msg|
              skip "intermittent failures on CI (TODO: fix this)" if ENV["CI"]

              # if Msh.ruby_2_4?
              #   expect(msg).to eq(["\r\necho msh ftw"])
              # else
                expect(msg).to eq(["\r\ninterpreter> echo msh ftw"])
              # end
            end
          end
        end
      end
    end
  end
end
