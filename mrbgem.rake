require "msh/version"

MRuby::Gem::Specification.new("mruby-bin-msh") do |spec| # rubocop:disable Metrics/BlockLength
  spec.license = "MIT"
  spec.author  = "Mark Delk"
  spec.summary = "Ruby shell"
  spec.version = Msh::VERSION
  spec.bins    = ["msh"]

  {
    "errno" => "iij",
    "process" => "iij",
    "exec" => "haconiwa"
  }.each do |gem, author|
    spec.add_dependency "mruby-#{gem}", :github => "#{author}/mruby-#{gem}"
  end

  %w[
    metaprog
    io
    print
    math
    struct
    enum-ext
    string-ext
    numeric-ext
    array-ext
    hash-ext
    object-ext
    toplevel-ext
    kernel-ext
    logger
    env
    eval
    method
    require

    bin-mruby
    bin-mirb
    bin-strip
  ].each do |gem|
    spec.add_dependency "mruby-#{gem}"
  end
end
