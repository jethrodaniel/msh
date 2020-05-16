# frozen_string_literal: true

def temp_dir
  FileUtils.mkdir_p File.join(Msh.root.realpath, "tmp")
  t = Msh.root.join "tmp"
  FileUtils.mkdir_p(t.realpath)
  t
end

def file name, content
  temp_dir
  File.open(name, "w") { |f| f.puts content }
end

def expect_file name, content
  expect(File.read(name)).to eq content
end

require "fileutils"

describe "redirections" do
  subject { Msh::Interpreter.new }
  before(:all) do
    FileUtils.rm_rf temp_dir
    temp_dir
    Dir.chdir Msh.root
  end

  def sh cmd, status
    expect(subject.interpret(cmd)).to eq status
  end

  describe ">" do
    it "redirects to a file, overwriting its contents" do
      skip "fails on CI" if ENV["CI"]
      file "tmp/msh", "mccoy"
      sh "echo bones > tmp/msh", 0
      expect_file "tmp/msh", "bones\n"
    end
    it "redirects the nth file descriptor" do
      skip "fails on CI" if ENV["CI"]
      file "tmp/msh", "mccoy"
      sh "echoo bones 2> tmp/msh", 1
      expect_file "tmp/msh", "No such file or directory - echoo\n"
    end
  end

  describe ">>" do
    it "redirects to a file, appending to its contents" do
      skip "fails on CI" if ENV["CI"]
      file "tmp/msh", "mccoy"
      sh "echo bones >> tmp/msh", 0
      expect_file "tmp/msh", "mccoy\nbones\n"
    end
    it "redirects the nth file descriptor" do
      skip "fails on CI" if ENV["CI"]
      file "tmp/msh", "mccoy"
      sh "echoo bones 2> tmp/msh", 1
      expect_file "tmp/msh", "No such file or directory - echoo\n"
    end
  end

  describe "<" do
    it "redirects input" do
      skip "fails on CI" if ENV["CI"]
      file "tmp/msh", "mccoy"
      sh "cat < tmp/msh > tmp/msh1", 0
      expect_file "tmp/msh1", "mccoy\n"
    end
    it "redirects input from the nth file descriptor" do
      skip "fails on CI" if ENV["CI"]
      file "tmp/msh", "mccoy"
      sh "cat < tmp/msh > tmp/msh1", 0
      expect_file "tmp/msh1", "mccoy\n"
    end
  end
end
