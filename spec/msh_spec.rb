# frozen_string_literal: true

RSpec.describe Msh do
  it "has a version number" do
    expect(Msh::VERSION).not_to be nil
  end

  describe ".root" do
    it "is the path to msh's root directory" do
      expect(Msh.root).to be_a Pathname
      expect(Msh.root.realpath.to_s).to end_with("msh")
    end
  end

  describe ".man_path" do
    it "is the path to msh's man/ directory" do
      expect(Msh.man_dir).to be_a Pathname
      expect(Msh.man_dir.realpath.to_s).to end_with("msh/man")
    end
  end

  describe ".start" do
    context "when ARGV is empty" do
      it "starts msh interactively" do
        skip
      end
    end

    context "when ARGV is not empty" do
      it "starts msh with each ARGV as an input msh script" do
        skip
      end
    end
  end
end
