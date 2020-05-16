# frozen_string_literal: true

def file name, content
  File.open(name, "w") { |f| f.puts content }
end

def expect_file name, content
  expect(File.read(name)).to eq content
end

describe "redirections" do
  subject { Msh::Interpreter.new }
  after(:all) { Dir.glob("/tmp/msh*") { |f| File.delete(f) } }

  def sh cmd, status
    expect(subject.interpret(cmd)).to eq status
  end

  describe ">" do
    it "redirects to a file, overwriting its contents" do
      file "/tmp/msh", "mccoy"
      sh "echo bones > /tmp/msh", 0
      expect_file "/tmp/msh", "bones\n"
    end
    it "redirects the nth file descriptor" do
      file "/tmp/msh", "mccoy"
      sh "echoo bones 2> /tmp/msh", 1
      expect_file "/tmp/msh", "No such file or directory - echoo\n"
    end
  end

  describe ">>" do
    it "redirects to a file, appending to its contents" do
      file "/tmp/msh", "mccoy"
      sh "echo bones >> /tmp/msh", 0
      expect_file "/tmp/msh", "mccoy\nbones\n"
    end
    it "redirects the nth file descriptor" do
      file "/tmp/msh", "mccoy"
      sh "echoo bones 2> /tmp/msh", 1
      expect_file "/tmp/msh", "No such file or directory - echoo\n"
    end
  end

  describe "<" do
    # it "redirects input" do
    #   skip
    #   file "/tmp/msh", "mccoy"
    #   expect(sh.interpret("cat < /tmp/msh > /tmp/msh")).to eq 0
    #   expect(File.read("/tmp/msh")).to eq "mccoy\nbones\n"
    # end
    # it "redirects the nth file descriptor" do
    #   skip
    #   file "/tmp/msh", "mccoy"
    #   expect_file "/tmp/msh", "No such file or directory - echoo\n"
    # end
  end
end
