# frozen_string_literal: true

require "bundler/setup"

require "rspec"

RSpec.configure do |config|
  # expect().to be_true
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
end

ENV["MSH_TESTING"] = "true"
ENV["INPUTRC"] = "/dev/null"

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

# Run a command, return combined std err and std out. Sets terminal display to
# 80 col width
#
# @param command_string [String]
# @return [String]
def sh command_string
  with_80_columns do
    `2>&1 #{command_string}`
  end
end

require "pty"
require "expect"

# TODO: wrapper around `PTY.spawn ...`
#
# @example
#   run_iteractively "msh" do
#     expect(input).to eq("interpreter> ")
#     type "hist"
#     expect(output).to eq("...")
#   end
#
# def run_iteractively cmd
# end

require "yaml"

# spec/fixtures/examples.yml uses this
require "ast"
include AST::Sexp

class Examples
  def self.passing
    examples.select { |_k, v| v[:valid] }
  end

  def self.failing
    examples.reject { |_k, v| v[:valid] }
  end

  def self.examples
    # https://github.com/puppetlabs/vmpooler/issues/240#issuecomment-354682704
    YAML.safe_load(File.read("spec/fixtures/examples.yml"), [Symbol])
        .dig(:examples)
  end
end
