# frozen_string_literal: true

RSpec.describe Msh do
  it "has a version number" do
    expect(Msh::VERSION).not_to be nil
  end
end

RSpec.describe "msh" do
  it "-h, --help" do
    expect(`msh -h`).to eq <<~MSG
      Usage: msh <command> [options]... [file]...

      msh is a ruby shell

      To file issues or contribute, see https://github.com/jethrodaniel/msh.

      commands:
          lexer                            run the lexer
          parser                           run the parser
          <blank>                          run the interpreter

      options:
          -h, --help                       print this help
          -V, --version                    show the version
              --copyright, --license       show the copyright
    MSG
    expect(`msh -h`).to eq `msh --help`
  end

  it "-V, --version" do
    msg = "msh version #{Msh::VERSION}\n"
    expect(`msh -V`).to eq msg
    expect(`msh --version`).to eq msg
  end

  it "--license, --copyright" do
    license = File.read((Pathname.new(__dir__) + "../license.txt"))
    expect(`msh --license`).to eq license
    expect(`msh --copyright`).to eq license
  end

  it "lexer" do
    skip
  end

  it "parser" do
    skip
  end

  it "-c" do
    skip
  end

  it "<FILE>" do
    skip
  end
end
