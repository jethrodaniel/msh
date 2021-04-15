begin
  require "msh/version"
  msh = Gem::Specification.find_by_name("msh")
rescue LoadError => e
  abort e.message
end

MRuby::Gem::Specification.new("mruby-bin-#{msh.name}") do |spec|
  %i[license author summary version].each { |attr| spec.send("#{attr}=", msh.send(attr)) }
  spec.bins = msh.executables

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
    exit
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
    require
    string-ext
    struct
    toplevel-ext
  ].each do |gem|
    spec.add_dependency "mruby-#{gem}"
  end
end