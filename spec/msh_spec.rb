RSpec.describe Msh do
  it "has a version number" do
    expect(Msh::VERSION).not_to be nil
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
