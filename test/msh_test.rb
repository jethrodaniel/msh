require_relative "init"

context "Msh" do
  test "VERSION" do
    refute(Msh::VERSION.nil?)
  end

  context ".start" do
    context "when ARGV is empty" do
      _test "starts msh interactively" do
      end
    end

    context "when ARGV is not empty" do
      _test "starts msh with each ARGV as an input msh script" do
      end
    end
  end
end
