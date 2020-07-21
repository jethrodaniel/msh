describe "last status" do
  subject { Msh::Interpreter.new }

  def sh cmd, status
    expect(subject.interpret(cmd)).to eq status
  end

  describe "$?" do
    it "holds the exit code of the last command that was ran" do
      out, err = capture_subprocess_io do
        sh <<~MSH, 0
          err
          echo $?
        MSH
      end
      expect(out).to eq("1\n")
      expect(err).to eq("No such file or directory - err\n")
    end

    it "errors if there is no last command status" do
      out, err = capture_subprocess_io do
        sh <<~MSH, 0
          echo $?
        MSH
      end
      expect(out).to eq("\n")
      expect(err).to eq("no last command to retrieve status for\n")
    end
  end
end
