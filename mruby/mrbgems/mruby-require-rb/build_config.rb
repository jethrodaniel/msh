MRuby::Build.new do |conf|
  toolchain :gcc
  conf.gem  "."
  enable_debug
  conf.mrbc do |mrbc|
    # The -g option is required for line numbers
    mrbc.compile_options = "-g -B%{funcname} -o-"
  end
  conf.enable_test
end
