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
    it "redirects input" do
      file "/tmp/msh", "mccoy"
      sh "cat < /tmp/msh > /tmp/msh1", 0
      expect_file "/tmp/msh1", "mccoy\n"
    end
    it "redirects input from the nth file descriptor" do
      file "/tmp/msh", "mccoy"
      sh "cat < /tmp/msh > /tmp/msh1", 0
      expect_file "/tmp/msh1", "mccoy\n"
    end
  end
end
