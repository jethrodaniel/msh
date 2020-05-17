# frozen_string_literal: true

def file name, content
  File.open(name, "w") { |f| f.puts content }
end

def expect_file name, content
  expect(File.read(name)).to eq content
end

describe "redirections" do
  subject { Msh::Interpreter.new }

  def sh cmd, status
    expect(subject.interpret(cmd)).to eq status
  end

  describe ">" do
    it "redirects to a file, overwriting its contents" do
      with_temp_files do
        file "a", "mccoy"
        sh "echo bones > a", 0
        expect_file "a", "bones\n"
      end
    end
    it "redirects the nth file descriptor" do
      with_temp_files do
        file "b", "mccoy"
        sh "echoo bones 2> b", 1
        expect_file "b", "No such file or directory - echoo\n"
      end
    end
  end

  describe ">>" do
    it "redirects to a file, appending to its contents" do
      with_temp_files do
        file "a", "mccoy"
        sh "echo bones >> a", 0
        expect_file "a", "mccoy\nbones\n"
      end
    end
    it "redirects the nth file descriptor" do
      with_temp_files do
        file "b", "mccoy"
        sh "echoo bones 2> b", 1
        expect_file "b", "No such file or directory - echoo\n"
      end
    end
  end

  describe "<" do
    it "redirects input" do
      with_temp_files do
        file "a", "mccoy"
        sh "cat < a > b", 0
        expect_file "b", "mccoy\n"
      end
    end
    it "redirects input from the nth file descriptor" do
      with_temp_files do
        file "a", "mccoy"
        sh "cat < a > b", 0
        expect_file "b", "mccoy\n"
      end
    end
  end

  describe "&>" do
    it "redirects output to a file, overwriting contents with stdout and stderr" do
      output = <<~OUT
        this goes to std err
        and this goes to std out
      OUT

      with_temp_files do
        sh "ruby #{Msh.root}/spec/fixtures/stdout_and_stderr.rb &> a", 0
        expect_file "a", output
      end
    end
  end
end
