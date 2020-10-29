require "rspec/core/rake_task"

task :test => :spec
RSpec::Core::RakeTask.new :spec
