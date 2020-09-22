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
    Dir["test/**/*_test.rb"].each do |t|
      sh "bundle exec ruby #{t}"
    end
  end
end

task :spec => %w[install test:bench test:rspec test:doctest]
