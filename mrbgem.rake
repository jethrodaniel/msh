# frozen_string_literal: true

MRuby::Gem::Specification.new("mruby-bin-msh") do |spec|
  spec.license = "MIT"
  spec.author  = "Mark Delk"
  spec.summary = "Ruby shell"
  # spec.version =
  spec.bins = ["msh"]
  spec.add_dependency "mruby-onig-regexp"
  spec.add_dependency "mruby-logger"
  spec.add_dependency "mruby-env"
  spec.add_dependency "mruby-require"
end
