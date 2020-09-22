require "yard"
require "yard/doctest/rake"
require "rspec/core/rake_task"

namespace :test do
  RSpec::Core::RakeTask.new :rspec

  YARD::Doctest::RakeTask.new :doctest do |t|
    t.doctest_opts = %w[--verbose --pride]
    t.pattern = "lib/**/*.rb"
  end

  task :bench do
    sh "bundle exec ruby #{Dir["test/**/*_test.rb"].join(' ')}"
  end
end

task :spec => %w[install test:bench test:rspec test:doctest]
