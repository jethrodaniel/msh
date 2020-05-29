# frozen_string_literal: true

DEV_CONF = <<~'RB'
  # Turn on `enable_debug` for better debugging
  enable_debug

  # mrbc settings
  conf.mrbc do |mrbc|
    # The -g option is required for line numbers
    mrbc.compile_options = "-g -B%{funcname} -o-"
  end

  # conf.enable_test
  conf.enable_bintest

  # conf.gem core: 'mruby-bin-debugger'
  # conf.cc.defines << 'MRB_ENABLE_DEBUG_HOOK'
RB

BUILD_CONFIG = <<~RB
  MRuby::Build.new do |conf|
    toolchain :gcc
    conf.gem  "../.."

    #{DEV_CONF unless ENV['RELEASE']}

    # reduce binary size some
    conf.linker.flags << "-Wl,--gc-sections"
    conf.cc.flags << "-Os" << "-ffunction-sections -fdata-sections"
  end
RB

def make_file name, source
  File.open(name, "w") { |f| f.puts source }
end

task :mruby do
  Dir.chdir "third_party/mruby" do
    sh "git checkout -- ."
    make_file "build_config.rb", BUILD_CONFIG
    sh "make clean"
    sh "make all test"
    sh "strip -s -R .comment -R .gnu.version --strip-unneeded ./bin/msh" if ENV["RELEASE"]
    sh "cp -v bin/msh ../../"
  end
end
