# frozen_string_literal: true

RSpec.describe Msh::Configuration do
  it "has configuration abilities" do
    expect(Msh.configuration).not_to be nil

    expect(Msh.configuration.color).to be true
    expect(Msh.configuration.history).to eq(:size => 2_048)
    expect(Msh.configuration.prompt).to eq("$")

    Msh.configure do |c|
      c.color = false
      c.history = {:size => 1_000}
      c.prompt = "%"
    end

    expect(Msh.configuration.color).to be false
    expect(Msh.configuration.history).to eq(:size => 1_000)
    expect(Msh.configuration.prompt).to eq("%")
  end
end
