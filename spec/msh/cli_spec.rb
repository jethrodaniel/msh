# frozen_string_literal: true

RSpec.describe "msh" do
  it "-h, --help" do
    expect(sh("msh -h")).to eq <<~MSG
      Usage:
          msh [options]... [file]...

      Options:
          -h, --help                       print this help
          -V, --version                    show the version   (0.1.0)
              --copyright, --license       show the copyright (MIT)
          -c  <cmd_string>                 runs <cmd_string> as shell input
    MSG
    expect(sh("msh -h")).to eq `msh --help`
  end

  it "-V, --version" do
    msg = "msh version #{Msh::VERSION}\n"
    expect(sh("msh -V")).to eq msg
    expect(sh("msh --version")).to eq msg
  end

  it "--license, --copyright" do
    license = File.read(Msh.root + "license.txt")
    expect(sh("msh --license")).to eq license
    expect(sh("msh --copyright")).to eq license
  end

  describe "-c <cmd_string>" do
    it "runs the command string as shell input" do
      expect(sh('msh -c "file readme.md"')).to eq(<<~SH)
        readme.md: UTF-8 Unicode text
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
      File.open("test.msh", "w") { |f| f.puts "echo such wow" }
      expect(sh("msh .msh")).to eq(<<~SH)
        such wow
      SH
      File.delete("test.msh")
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
