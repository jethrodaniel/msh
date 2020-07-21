describe "if/else" do
  subject { Msh::Interpreter.new }

  def sh cmd, status
    expect(subject.interpret(cmd)).to eq status
  end

  describe "if <expr> <body> end" do
    it "runs the <body> code only if <expr> exits non-zero" do
      skip
      out, err = capture_subprocess_io do
        sh <<~MSH, 0
          if echo condition
            echo body
          end
        MSH
      end
      expect(out).to eq("condition\nbody\n")
      expect(err).to eq("")
    end
  end
end
