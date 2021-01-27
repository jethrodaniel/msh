require "spec_helper"
require "msh/version"

describe Msh do
  it "has a version number" do
    _(Msh::VERSION).must_equal "0.3.0"
  end
end
