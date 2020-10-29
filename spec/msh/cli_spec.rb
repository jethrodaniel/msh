describe "msh" do
  it "-h, --help" do
    expect(sh("msh -h")).to eq <<~MSG
      Usage:
          msh [options]... [file]...

      Options:
          -V, --version  show the version
          -c, --command  runs a string as shell input
          -h, --help     print this help
    MSG
    expect(sh("msh -h")).to eq `msh --help`
  end

  it "-V, --version" do
    msg = "msh v#{Msh::VERSION}"
    expect(sh("msh --version")).to include msg
  end

  describe "-c <cmd_string>" do
    it "runs the command string as shell input" do
      expect(sh("msh -c ./spec/fixtures/stdout_and_stderr.rb")).to eq(<<~SH)
        this goes to std err
        and this goes to std out
      SH
    end

    context "when missing a string" do
      it "aborts with an error message" do
        expect(sh("msh -c")).to eq("missing argument: -c\n")
      end
    end
  end

  describe "[file]..." do
    it "runs [files]... as shell scripts" do
      with_temp_files do
        file "test.msh", "echo such wow"
        expect(sh("msh test.msh")).to eq(<<~SH)
          such wow
        SH
      end
    end

    context "when no files are supplied" do
      # it "runs interactively" do
      #   # skip "intermittent failures on CI (TODO: fix this)" if ENV["CI"]
      #   PTY.spawn("msh") do |read, write, _pid|
      #     read.expect(/interpreter> /, 1) do |msg|
      #       expect(msg).to eq(["interpreter> "])
      #     end
      #   end
      # end
    end
  end
end
