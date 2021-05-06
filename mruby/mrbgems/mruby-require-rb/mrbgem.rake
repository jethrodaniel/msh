MRuby::Gem::Specification.new('mruby-array-ext') do |spec|
  spec.license = 'MIT'
  spec.author  = "Mark Delk <jethrodaniel@gmail.com>"
  spec.summary = "`require`, `require_relative`, and `load` for MRuby, in pure Ruby"
  spec.add_dependency "mruby-io"
  spec.add_dependency "mruby-eval"
end
