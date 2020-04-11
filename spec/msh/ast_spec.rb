# frozen_string_literal: true

require "msh/ast"

RSpec.describe Msh::AST::Command do
  subject do
    Msh::AST::Command.new :words => %w[echo hi]
  end

  it ".words" do
    expect(subject.words).to eq(%w[echo hi])
  end

  it ".==" do
    command = Msh::AST::Command.new :words => %w[echo hi]
    expect(command).to eq(subject)
  end

  it "#from_node" do
    node = s(:COMMAND,
             s(:WORD, "echo"),
             s(:WORD, "hi"))

    command = Msh::AST::Command.from_node node
    expect(subject).to eq(command)
  end
end

RSpec.describe Msh::AST::AndOr do
  let(:left)  { Msh::AST::Command.new :words => %w[fortune] }
  let(:right) { Msh::AST::Command.new :words => %w[echo no fortune] }
  subject { Msh::AST::AndOr.new :left => left, :right => right }

  it ".left" do
    expect(subject.left).to eq(left)
  end

  it ".right" do
    expect(subject.right).to eq(right)
  end

  it ".==" do
    and_or = Msh::AST::AndOr.new :left => left, :right => right
    and_ = Msh::AST::And.new :left => left, :right => right
    or_ = Msh::AST::Or.new :left => left, :right => right
    expect(subject).to eq(and_or)
    expect(subject).to eq(and_)
    expect(subject).to eq(or_)
  end
end

RSpec.describe Msh::AST::Pipeline do
  let :a do
    Msh::AST::Piped.new \
      :command => Msh::AST::Command.new(:words => %w[fortune]),
      :stdin => $stdin,
      :stdout => $stdout,
      :stderr => $stderr,
      :close_stdin => false,
      :close_stdout => false
  end
  let :b do
    Msh::AST::Piped.new \
      :command => Msh::AST::Command.new(:words => %w[cowsay]),
      :stdin => $stdin,
      :stdout => $stdout,
      :stderr => $stderr,
      :close_stdin => false,
      :close_stdout => false
  end
  subject { Msh::AST::Pipeline.new :piped => [a, b] }

  it ".piped" do
    expect(subject.piped).to eq([a, b])
  end

  it ".==" do
    skip
    # a = Msh::AST::Command.new :words => %w[fortune]
    # b = Msh::AST::Command.new :words => %w[cowsay]
    # p = Msh::AST::Pipeline.new :piped => [a, b]
    # expect(subject).to eq(p)
  end
end
