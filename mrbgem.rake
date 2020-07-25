require "msh/version"

MRuby::Gem::Specification.new("mruby-bin-msh") do |spec| # rubocop:disable Metrics/BlockLength
  spec.license = "MIT"
  spec.author  = "Mark Delk"
  spec.summary = "Ruby shell"
  spec.version = Msh::VERSION
  spec.bins    = ["msh"]

  {
    "errno"   => "iij",
    "process" => "iij",
    "exec"    => "haconiwa"
  }.each do |gem, author|
    spec.add_dependency "mruby-#{gem}", :github => "#{author}/mruby-#{gem}"
  end

  %w[
    array-ext
    enum-ext
    env
    eval
    hash-ext
    io
    kernel-ext
    logger
    math
    metaprog
    method
    numeric-ext
    object-ext
    print
    string-ext
    struct
    toplevel-ext

    require

    bin-mirb
    bin-mruby
    bin-strip
  ].each do |gem|
    spec.add_dependency "mruby-#{gem}"
  end
end
