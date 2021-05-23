msh = Gem::Specification.find_by_name("msh")

MRuby::Gem::Specification.new("mruby-bin-#{msh.name}") do |spec|
  spec.bins = msh.executables
  %i[
    license
    author
    summary
    version
  ].each { |attr| spec.send("#{attr}=", msh.send(attr)) }

  %w[
    array-ext
    enum-ext
    eval
    exit
    hash-ext
    io
    kernel-ext
    math
    metaprog
    method
    numeric-ext
    object-ext
    print
    string-ext
    struct
    toplevel-ext
  ].each do |gem|
    spec.add_dependency "mruby-#{gem}", :core => "mruby-#{gem}"
  end

  %w[
    env
  ].each do |gem|
    spec.add_dependency "mruby-#{gem}"
  end

  {
    "errno"   => "iij",
    "exec"    => "haconiwa",
    "process" => "iij",
    "dir"     => "iij",
  }.each do |gem, author|
    spec.add_dependency "mruby-#{gem}", :github => "#{author}/mruby-#{gem}"
  end
end
