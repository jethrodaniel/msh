require_relative "../init"
require_relative "../helper"

context "msh" do
  test "-h, --help" do
    output = sh("msh -h")
    asserted = <<~MSG
      Usage:
          msh [options]... [file]...

      Options:
          -V, --version  show the version
          -c, --command  runs a string as shell input
          -h, --help     print this help
    MSG
    assert(output == asserted)
    assert(sh("msh -h") == `msh --help`)
  end

  test "-V, --version" do
    msg = "msh version #{Msh::VERSION}\n"
    assert(sh("msh -V") == msg)
    assert(sh("msh --version") == msg)
  end

  context "-c <cmd_string>" do
    test "runs the command string as shell input" do
      output = sh("msh -c 'echo hello there'")
      assert(output == "hello there\n")
    end

    context "when missing a string" do
      test "aborts with an error message" do
        assert(sh("msh -c") == "missing argument: -c\n")
      end
    end
  end

  context "[file]..." do
    test "runs [files]... as shell scripts" do
      with_temp_files do
        file f = "test.msh", text = "echo such wow"
        output = sh("msh #{f}")
        assert(output == "such wow\n")
      end
    end

    context "when no files are supplied" do
    end
  end
end
