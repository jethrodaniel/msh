MRuby::Build.new do |conf|
  toolchain :gcc

  conf.gem  "."

  # Turn on `enable_debug` for better debugging
  enable_debug

  conf.mrbc do |mrbc|
    # The -g option is required for line numbers
    mrbc.compile_options = "-g -B%{funcname} -o-"
  end

  # reduce binary size somewhat
  # conf.linker.flags << "-Wl,--gc-sections"
  # conf.cc.flags << "-Os" << "-ffunction-sections -fdata-sections"

  conf.enable_bintest
end
