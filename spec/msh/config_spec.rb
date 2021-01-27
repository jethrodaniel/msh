require "spec_helper"
require "msh/config"
require "msh/interpreter"

describe Msh::Config do
  it "has config abilities" do
    _(Msh.config).wont_be_nil

    _(Msh.config.color).must_equal true
    _(Msh.config.history_lines).must_equal 2_048
    _(Msh.config.repl).must_equal :irb

    Msh.configure do |c|
      c.color = false
      c.history_lines = 1_000
      c.repl = :pry
    end

    _(Msh.config.color).must_equal false
    _(Msh.config.history_lines).must_equal 1_000
    _(Msh.config.repl).must_equal :pry
  end

  def sh cmd, status
    _(Msh::Interpreter.new.interpret(cmd)).must_equal status
  end

  it "looks for startup files" do
    # sh "ls", 0
    skip
  end
end
