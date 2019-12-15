# frozen_string_literal: true

require "bundler/setup"
require "msh"

RSpec.configure do |config|
  # expect().to be_true
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
end

ENV["MSH_TESTING"] = "true"

require_relative "examples"
