require "msh/config"
require "msh/interpreter"

describe Msh::Config do
  it "has config abilities" do
    expect(Msh.config).not_to be nil

    expect(Msh.config.color).to be true
    expect(Msh.config.history_lines).to eq(2_048)
    expect(Msh.config.repl).to eq(:irb)

    Msh.configure do |c|
      c.color = false
      c.history_lines = 1_000
      c.repl = :pry
    end

    expect(Msh.config.color).to be false
    expect(Msh.config.history_lines).to eq(1_000)
    expect(Msh.config.repl).to eq(:pry)
  end

  subject { Msh::Interpreter.new }

  def sh cmd, status
    expect(subject.interpret(cmd)).to eq status
  end

  it "looks for startup files" do
    # sh "ls", 0
    skip
  end
end
