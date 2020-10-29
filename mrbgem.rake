begin
  require "msh/version"
  msh = Gem::Specification.find_by_name("msh")
rescue LoadError => e
  abort e.message
end

MRuby::Gem::Specification.new("mruby-bin-#{msh.name}") do |spec|
  %i[license author summary version].each { |attr| spec.send("#{attr}=", msh.send(attr)) }
  spec.bins = %w[msh]
  # spec.rbfiles = %w[mrblib/msh.rb]

  {
    # "errno"   => "iij",
    "process" => "iij",
    # "exec"    => "haconiwa"
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
    string-ext
    struct
    toplevel-ext

    bin-mirb
    bin-mruby
    bin-strip
  ].each do |gem|
    spec.add_dependency "mruby-#{gem}"
  end
end
