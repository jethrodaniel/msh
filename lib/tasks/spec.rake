require "yard"
require "yard/doctest/rake"
require "rspec/core/rake_task"

namespace :test do
  RSpec::Core::RakeTask.new :rspec

  YARD::Doctest::RakeTask.new :doctest do |t|
    t.doctest_opts = %w[--verbose --pride]
    t.pattern = "lib/**/*.rb"
  end

  task :unit do
    path = File.absolute_path File.join(__dir__, "../..")
    path = File.join(path, "test/**/*.rb")
    files = Dir.glob(path)
    # files.each do |f|
    #   sh %(ruby -I third_party/mruby/test -r assert -e 'load "#{f}"; report')
    #   puts
    # end
    loads = files.map { |f| "load '#{f}';" }.join " "
    # script = "Dir.glob('test/**/*.rb').each(&method(:load))"
    # sh "ruby -I third_party/mruby/test -r assert -e \"#{script}; report\""
    sh "ruby -I third_party/mruby/test -r assert -e \"#{loads}; report\""
    puts
  end
end

task :test => %w[test:unit test:rspec test:doctest]
task :spec => :test
