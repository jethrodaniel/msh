# = mruby-require-rb
#
# `require`, `require_relative`, and `load` for MRuby, in pure Ruby.
#
# Documentation was taken from `ri`:
#
# ```
# $  ruby -v
# ruby 3.0.0p0 (2020-12-25 revision 95aff21468) [x86_64-linux]
# $ ri --version
# ri 6.3.0
# $ ri Kernel#load -f markdown -T
# ```
#
module Kernel
  # # Kernel#load
  #
  # (from ruby core)
  # ---
  #     load(filename, wrap=false)   -> true
  #
  # ---
  #
  # Loads and executes the Ruby program in the file *filename*.
  #
  # If the filename is an absolute path (e.g. starts with '/'), the file
  # will be loaded directly using the absolute path.
  #
  # If the filename is an explicit relative path (e.g. starts with './' or
  # '../'), the file will be loaded using the relative path from the current
  # directory.
  #
  # Otherwise, the file will be searched for in the library directories
  # listed in `$LOAD_PATH` (`$:`). If the file is found in a directory, it
  # will attempt to load the file relative to that directory.  If the file
  # is not found in any of the directories in `$LOAD_PATH`, the file will be
  # loaded using the relative path from the current directory.
  #
  # If the file doesn't exist when there is an attempt to load it, a
  # LoadError will be raised.
  #
  # If the optional *wrap* parameter is `true`, the loaded script will be
  # executed under an anonymous module, protecting the calling program's
  # global namespace. In no circumstance will any local variables in the
  # loaded file be propagated to the loading environment.
  #
  def load file, wrap = false
    file = if ['/', './', '../'].any? { |s| file.start_with?(s) }
             file
           else
             dir = $:.find do |dir|
               f = File.join(dir, file)
               File.exist?(f)
             end
             dir ? File.join(dir, file) : file
           end

    unless File.file?(file)
      raise LoadError, "cannot load such file -- `#{file}`"
    end

    if wrap
      eval "Module.new { #{File.read(file)} }"
    else
      eval File.read(file)
    end

    true
  end
end

##

#require 'tmpdir'
#Dir.chdir(Dir.mktmpdir)

###

## load 'missing'

#require 'minitest/autorun'
#require 'minitest/spec'

#include Require

#describe 'require/load stuff' do
#  before do
#    Dir.chdir Dir.mktmpdir
#  end

#  describe '.require' do
#    it 'loads constants' do
#      _(Object.const_defined?(:TEST)).wont_equal true
#      File.open('test', 'w') { |f| f.puts "TEST = true" }
#      load 'test'
#      _(Object.const_defined?(:TEST)).must_equal true
#    end

#    it 'loads modules' do
#      _(Object.const_defined?(:TestModule)).wont_equal true
#      File.open('test', 'w') { |f| f.puts "module TestModule; end" }
#      load 'test'
#      _(Object.const_defined?(:TestModule)).must_equal true
#    end

#    it 'loads classes' do
#      _(Object.const_defined?(:TestClass)).wont_equal true
#      File.open('test', 'w') { |f| f.puts "class TestClass; end" }
#      load 'test'
#      _(Object.const_defined?(:TestClass)).must_equal true
#    end

#    it "raises a LoadError if a file by that name can't be found" do
#      err = assert_raises(LoadError) { load 'missing' }
#      _(err.message).must_equal "cannot load such file -- `missing`"
#    end
#  end
#end
