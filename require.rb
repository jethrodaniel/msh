module Require
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
    raise LoadError, "can't load `#{file}`" unless File.file?(file)
    eval File.read(file)
  end
end

##

require 'tmpdir'
Dir.chdir(Dir.mktmpdir)

##

# load 'missing'

require 'minitest/autorun'
require 'minitest/spec'

include Require

describe 'require/load stuff' do
  before do
    Dir.chdir Dir.mktmpdir
  end

  describe '.require' do
    it 'loads constants' do
      _(Object.const_defined?(:TEST)).wont_equal true
      File.open('test', 'w') { |f| f.puts "TEST = true" }
      load 'test'
      _(Object.const_defined?(:TEST)).must_equal true
    end

    it 'loads modules' do
      _(Object.const_defined?(:TestModule)).wont_equal true
      File.open('test', 'w') { |f| f.puts "module TestModule; end" }
      load 'test'
      _(Object.const_defined?(:TestModule)).must_equal true
    end

    it 'loads classes' do
      _(Object.const_defined?(:TestClass)).wont_equal true
      File.open('test', 'w') { |f| f.puts "class TestClass; end" }
      load 'test'
      _(Object.const_defined?(:TestClass)).must_equal true
    end

    it "raises a LoadError if a file by that name can't be found" do
      err = assert_raises(LoadError) { load 'missing' }
      _(err.message).must_equal "can't load `missing`"
    end
  end
end
