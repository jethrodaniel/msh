require "rubocop/rake_task"
RuboCop::RakeTask.new :lint do |t|
  t.options = %w[--display-cop-names -c.rubocop.yml]
end
