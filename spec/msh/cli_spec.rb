require "spec_helper"

describe "msh" do
  it "-h, --help" do
    _(sh("msh -h")).must_equal <<~MSG
      Usage:
          msh [options]... [file]...

      Options:
          -V, --version  show the version
          -c, --command  runs a string as shell input
          -h, --help     print this help
    MSG
    _(sh("msh -h")).must_equal `msh --help`
  end

  it "-V, --version" do
    msg = "msh v#{Msh::VERSION}"
    _(sh("msh --version")).must_include msg
  end

  describe "-c <cmd_string>" do
    it "runs the command string as shell input" do
      _(sh("msh -c ./spec/fixtures/stdout_and_stderr.rb")).must_equal <<~SH
        this goes to std err
        and this goes to std out
      SH
    end

    describe "when missing a string" do
      it "aborts with an error message" do
        _(sh("msh -c")).must_equal "missing argument: -c\n"
      end
    end
  end

  describe "[file]..." do
    it "runs [files]... as shell scripts" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          File.open("test.msh", "w") { |f| f.puts "echo such wow" }
          _(sh("msh test.msh")).must_equal <<~SH
            such wow
          SH
        end
      end
    end

    describe "when no files are supplied" do
      # it "runs interactively" do
      #   # skip "intermittent failures on CI (TODO: fix this)" if ENV["CI"]
      #   PTY.spawn("msh") do |read, write, _pid|
      #     read._(/interpreter> /, 1) do |msg|
      #       _(msg).to eq(["interpreter> "])
      #     end
      #   end
      # end
    end
  end
end
