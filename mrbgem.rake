# frozen_string_literal: true

MRuby::Gem::Specification.new("mruby-bin-msh") do |spec|
  spec.license = "MIT"
  spec.author  = "Mark Delk"
  spec.summary = "Ruby shell"
  # spec.version =
  spec.bins = ["msh"]

  minimal_default_gems spec

  spec.add_dependency "mruby-logger"
  spec.add_dependency "mruby-env"
  spec.add_dependency "mruby-require"

  # reduce binary size some
  spec.mruby.linker.flags << "-Wl,--gc-sections"
  spec.mruby.cc.flags << "-Os" << "-ffunction-sections -fdata-sections"
end

def minimal_default_gems spec
  spec.add_dependency "mruby-metaprog"
  spec.add_dependency "mruby-io"
  # spec.add_dependency "mruby-pack"
  # spec.add_dependency "mruby-sprintf"
  spec.add_dependency "mruby-print"
  # spec.add_dependency "mruby-math"
  # spec.add_dependency "mruby-time"
  # spec.add_dependency "mruby-struct"
  # spec.add_dependency "mruby-compar-ext"
  # spec.add_dependency "mruby-enum-ext"
  # spec.add_dependency "mruby-string-ext"
  spec.add_dependency "mruby-numeric-ext"
  # spec.add_dependency "mruby-array-ext"
  # spec.add_dependency "mruby-hash-ext"
  # spec.add_dependency "mruby-range-ext"
  # spec.add_dependency "mruby-proc-ext"
  # spec.add_dependency "mruby-symbol-ext"
  # spec.add_dependency "mruby-random"
  spec.add_dependency "mruby-object-ext"
  # spec.add_dependency "mruby-objectspace"
  # spec.add_dependency "mruby-fiber"
  # Use Enumerator class (require mruby-fiber)
  # spec.add_dependency "mruby-enumerator"
  # Use Enumerator::Lazy class (require mruby-enumerator)
  # spec.add_dependency "mruby-enum-lazy"

  spec.add_dependency "mruby-toplevel-ext"
end
