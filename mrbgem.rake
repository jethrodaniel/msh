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
  spec.add_dependency "mruby-optparse"
  # spec.add_dependency "mruby-file-stat"
  spec.add_dependency "mruby-require" # , :github => "jethrodaniel/mruby-require"
  spec.add_dependency "mruby-process", :github => "iij/mruby-process"
  spec.add_dependency "mruby-errno",   :github => "iij/mruby-errno"
  # https://github.com/iij/mruby-dir
  spec.add_dependency "mruby-ast",     :github => "jethrodaniel/mruby-ast"
  spec.add_dependency "mruby-exec",    :github => "haconiwa/mruby-exec"

  spec.rbfiles += Dir.glob(File.join(__dir__, "lib/**/*.rb"))
end

def minimal_default_gems spec
  # Meta-programming features
  spec.add_dependency "mruby-metaprog"

  # Use standard IO/File class
  spec.add_dependency "mruby-io"

  # # Use standard Array#pack, String#unpack methods
  # spec.add_dependency "mruby-pack"

  # # Use standard Kernel#sprintf method
  # spec.add_dependency "mruby-sprintf"

  # Use standard print/puts/p
  spec.add_dependency "mruby-print"

  # # Use standard Math module
  # spec.add_dependency "mruby-math"

  # # Use standard Time class
  # spec.add_dependency "mruby-time"

  # Use standard Struct class
  spec.add_dependency "mruby-struct"

  # # Use Comparable module extension
  # spec.add_dependency "mruby-compar-ext"

  # Use Enumerable module extension
  spec.add_dependency "mruby-enum-ext"

  # Use String class extension
  spec.add_dependency "mruby-string-ext"

  # Use Numeric class extension
  spec.add_dependency "mruby-numeric-ext"

  # # Use Array class extension
  # spec.add_dependency "mruby-array-ext"

  # # Use Hash class extension
  # spec.add_dependency "mruby-hash-ext"

  # # Use Range class extension
  # spec.add_dependency "mruby-range-ext"

  # # Use Proc class extension
  # spec.add_dependency "mruby-proc-ext"

  # # Use Symbol class extension
  # spec.add_dependency "mruby-symbol-ext"

  # # Use Random class
  # spec.add_dependency "mruby-random"

  # Use Object class extension
  spec.add_dependency "mruby-object-ext"

  # Use ObjectSpace class
  spec.add_dependency "mruby-objectspace"

  # # Use Fiber class
  # spec.add_dependency "mruby-fiber"

  # # Use Enumerator class (require mruby-fiber)
  # spec.add_dependency "mruby-enumerator"

  # # Use Enumerator::Lazy class (require mruby-enumerator)
  # spec.add_dependency "mruby-enum-lazy"

  # Use toplevel object (main) methods extension
  spec.add_dependency "mruby-toplevel-ext"

  # Generate mirb command
  spec.add_dependency "mruby-bin-mirb"

  # Generate mruby command
  spec.add_dependency "mruby-bin-mruby"

  # Generate mruby-strip command
  spec.add_dependency "mruby-bin-strip"

  # # Use Kernel module extension
  # spec.add_dependency "mruby-kernel-ext"

  # # Use class/module extension
  # spec.add_dependency "mruby-class-ext"

  # # Use mruby-compiler to build other mrbgems
  # spec.add_dependency "mruby-compiler"
end
