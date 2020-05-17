# frozen_string_literal: true

require "msh/configuration"
require "msh/interpreter"

describe Msh::Configuration do
  it "has configuration abilities" do
    expect(Msh.configuration).not_to be nil

    expect(Msh.configuration.color).to be true
    expect(Msh.configuration.history_lines).to eq(2_048)
    expect(Msh.configuration.repl).to eq(:irb)

    Msh.configure do |c|
      c.color = false
      c.history_lines = 1_000
      c.repl = :pry
    end

    expect(Msh.configuration.color).to be false
    expect(Msh.configuration.history_lines).to eq(1_000)
    expect(Msh.configuration.repl).to eq(:pry)
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
