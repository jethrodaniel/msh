require "pty"
require "expect"
require "yaml"
require "stringio"
require "tempfile"
require "tmpdir"
require "fileutils"

require "bundler/setup"
require "rspec"

require "msh"
require "msh/backports"

RSpec.configure do |config|
  # expect().to be_true
  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.max_formatted_output_length = ENV["VERBOSE"] ? 1_000 : 100
  end

  # Disable RSpec exposing methods globally on `Module` and `main`
  # config.disable_monkey_patching!
end

# ENV["INPUTRC"] = "/dev/null"

# @example
#   run_iteractively "msh" do
#     expect(input).to eq("interpreter> ")
#     type "hist"
#     expect(output).to eq("...")
#   end
#
# def run_iteractively cmd
# end

def with_80_columns
  return yield unless $stdout.isatty

  cols = `stty -a`.split("\n")
                  .first
                  .match(/.*rows (?<rows>\d+); columns (?<columns>\d+)/)
                  .named_captures["columns"]

  `stty columns 80`
  out = yield
  `stty columns #{cols}; stty sane`
  out
end

# Run a command, return combined std err and std out.
#
# @note sets terminal display to 80 col width
#
# @param command_string [String]
# @return [String]
def sh command_string
  with_80_columns do
    `2>&1 #{command_string}`
  end
end

# https://github.com/seattlerb/minitest/blob/6257210b7accfeb218b4388aaa36d3d45c5c41a5/lib/minitest/assertions.rb#L546
#
def capture_subprocess_io
  captured_stdout = Tempfile.new("out")
  captured_stderr = Tempfile.new("err")

  orig_stdout = $stdout.dup
  orig_stderr = $stderr.dup
  $stdout.reopen captured_stdout
  $stderr.reopen captured_stderr

  yield

  $stdout.rewind
  $stderr.rewind

  [captured_stdout.read, captured_stderr.read]
ensure
  captured_stdout.unlink
  captured_stderr.unlink
  $stdout.reopen orig_stdout
  $stderr.reopen orig_stderr
end

def with_temp_files
  temp = Dir.mktmpdir
  pwd = Dir.pwd
  Dir.chdir temp
  yield
  Dir.chdir pwd
  FileUtils.rm_f temp
end

def file name, content
  File.open(name, "w") { |f| f.puts content }
end

def expect_file name, content
  expect(File.read(name)).to eq content
end
