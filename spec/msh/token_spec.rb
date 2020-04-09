# frozen_string_literal: true

require "msh/token"

RSpec.describe Msh::Token do
  subject do
    Msh::Token.new :type => :WORD,
                   :value => "echo",
                   :line => 6,
                   :column => 2
  end

  it ".type" do
    expect(subject.type).to eq(:WORD)
  end

  it ".value" do
    expect(subject.value).to eq("echo")
  end

  it ".line" do
    expect(subject.line).to eq(6)
  end

  it ".column" do
    expect(subject.column).to eq(2)
  end

  it ".to_s" do
    expect(subject.to_s).to eq("[6:2-5][WORD, 'echo']")
  end
end
