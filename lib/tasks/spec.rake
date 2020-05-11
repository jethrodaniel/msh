# frozen_string_literal: true

require "yard"
require "yard/doctest/rake"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new :rspec

YARD::Doctest::RakeTask.new :doctest do |t|
  t.doctest_opts = %w[--verbose --pride]
  t.pattern = "lib/**/*.rb"
end

# task :test => :spec
task :spec => %i[rspec doctest]
