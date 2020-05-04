# frozen_string_literal: true

require "msh/documentation"
require "msh/interpreter"

require "stringio"
require "tempfile"

# https://github.com/seattlerb/minitest/blob/6257210b7accfeb218b4388aaa36d3d45c5c41a5/lib/minitest/assertions.rb#L546
#
# todo: more FD-specific, like
#
#     redirect 1, 2 do # redirects fd1 to fd2
#       ...
#     end
#
def capture_subprocess_io
  captured_stdout = Tempfile.new("out")
  captured_stderr = Tempfile.new("err")

  orig_stdout = $stdout.dup
  orig_stderr = $stderr.dup
  $stdout.reopen captured_stdout
  $stderr.reopen captured_stderr

  yield

  $stdout.rewind
  $stderr.rewind

  [captured_stdout.read, captured_stderr.read]
ensure
  captured_stdout.unlink
  captured_stderr.unlink
  $stdout.reopen orig_stdout
  $stderr.reopen orig_stderr
end

RSpec.describe Msh::Interpreter do
  subject { Msh::Interpreter.new }

  Examples.each do |code, data|
    it code do
      skip unless data[:interpreter_valid]

      ast = binding.eval(data[:ast], *binding.source_location)

      orig = $stdout
      buffer = StringIO.new

      out, err = capture_subprocess_io do
        out = subject.process(ast)
        expect(out).to eq data[:exit_code]
      end

      expect(out).to eq data[:output]
      expect(err).to eq data[:error]
    end
  end

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
    describe "help" do
      it "shows `msh` when called with no args" do
        skip
        man = File.read(Msh.root + "spec/fixtures/help/msh.txt")
        expect(sh("MANPAGER=cat msh -c help")).to eq(man)
      end

      it "has tab completion" do
        skip
      end

      Msh::Documentation.help_topics.each do |topic|
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
      # context "when interactive" do
      #   it "shows shell history" do
      #     skip "intermittent failures on CI (TODO: fix this)" if ENV["CI"]

      #     PTY.spawn("msh") do |read, write, _pid|
      #       read.expect(/interpreter> /, 1) do |msg|
      #         expect(msg).to eq(["interpreter> "])
      #       end

      #       write.puts "hist"
      #       read.expect("1 hist", 1) do |msg|
      #         expect(msg).to eq(["hist\r\n1 hist"])
      #       end

      #       write.puts "echo msh ftw"
      #       read.expect("msh ftw", 3) do |msg|
      #         # expect(msg).to eq(["\r\necho msh ftw"])
      #         expect(msg).to eq(["\r\ninterpreter> echo msh ftw"])
      #       end
      #     end
      #   end
      # end
    end
  end
end
