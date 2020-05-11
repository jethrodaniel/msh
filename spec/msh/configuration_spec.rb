# frozen_string_literal: true

require "msh/configuration"

RSpec.describe Msh::Configuration do
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

  it "looks for startup files" do
    skip
  end
end
