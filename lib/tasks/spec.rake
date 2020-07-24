require "yard"
require "yard/doctest/rake"
require "rspec/core/rake_task"

namespace :test do
  RSpec::Core::RakeTask.new :rspec

  YARD::Doctest::RakeTask.new :doctest do |t|
    t.doctest_opts = %w[--verbose --pride]
    t.pattern = "lib/**/*.rb"
  end
end

task :test => %w[test:rspec test:doctest]
task :spec => :test
