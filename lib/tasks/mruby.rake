# frozen_string_literal: true

BUILD_CONFIG = <<~RB
  MRuby::Build.new do |conf|
    toolchain :gcc

    conf.enable_bintest

    conf.gembox 'default'

    conf.cc.include_paths << "/home/jethro/code/ruby/msh/third_party/mruby/mrbgems/mruby-io/include/mruby/ext/"
    conf.gem :core => 'mruby-io'
    conf.gem '../..'

    # Turn on `enable_debug` for better debugging
    enable_debug

    # mrbc settings
    conf.mrbc do |mrbc|
      # The -g option is required for line numbers
      mrbc.compile_options = "-g -B%{funcname} -o-"
    end
  end
RB

def make_file name, source
  File.open(name, "w") { |f| f.puts source }
end

task :mruby do
  Dir.chdir "third_party/mruby" do
    # sh "git checkout -- ."
    make_file "build_config.rb", BUILD_CONFIG
    sh "make clean"
    sh "make"
    # sh "cp -v bin/msh ../../exe/"
    sh "cp -v bin/msh ../../"
    # sh "git checkout -- ."
  end
end
