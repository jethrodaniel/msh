DEV_CONF = <<-'RB'.freeze
  # Turn on `enable_debug` for better debugging
  conf.enable_debug

  # mrbc settings
  conf.mrbc do |mrbc|
    # The -g option is required for line numbers
    mrbc.compile_options = "-g -B%{funcname} -o-"
  end

  conf.enable_test
  # conf.enable_bintest

  # conf.gem core: 'mruby-bin-debugger'
  # conf.cc.defines << 'MRB_ENABLE_DEBUG_HOOK'
RB

BUILD_CONFIG = <<~RB.freeze
  MRuby::Build.new do |conf|
    toolchain :gcc

    conf.gem  "../.."
    #conf.gem  "../../.."

    #{DEV_CONF unless ENV['RELEASE']}

    # reduce binary size some
    conf.linker.flags << "-Wl,--gc-sections"
    conf.cc.flags << "-Os" << "-ffunction-sections -fdata-sections"
  end
RB

def make_file name, source
  File.open(name, "w") { |f| f.puts source }
end

directory "mrblib"
CLEAN << "mrblib" << "msh.rb" << "msh"

desc "consolidate msh into a single executable script"
task :consolidate => "msh.rb"
file "msh.rb" => "lib/msh.rb" do |t|
  sh "gem consolidate #{t.source} --no-stdlib --footer='Msh.start' > #{t.name}"
  sh "mv #{t.name} z"
  sh "echo '#!/usr/bin/env ruby' > #{t.name}"
  sh "cat lib/msh/mruby.rb >> #{t.name}"
  sh "cat z >> #{t.name}"
  sh "rm z"
  sh "chmod u+x #{t.name}"
end

directory "mrblib"
file "mrblib/msh.rb" => %w[msh.rb mrblib] do |t|
  sh "cp #{t.source} #{t.name}"
end
desc "creates an executable with MRuby"
task :mruby => ["mrblib/msh.rb", "mrblib"] do
  Dir.chdir "third_party/mruby" do
    make_file "target/msh.rb", BUILD_CONFIG
    make_file "build_config.rb", BUILD_CONFIG
    # sh "TARGET=msh rake clean all"
    sh "rake clean all"
    sh "strip -s -R .comment -R .gnu.version --strip-unneeded ./bin/msh" if ENV["RELEASE"]
    sh "cp -v bin/msh ../../"
  end
end
