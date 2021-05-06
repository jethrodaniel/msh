def in_fixture_dir
  Dir.chdir File.join(File.dirname(__FILE__), 'fixtures') do
    yield
  end
end

def assert_defines o
  assert_false Object.const_defined?(o), "#{o} shouldn't be defined yet"
  yield
  assert_true Object.const_defined?(o), "#{o} shouldn't be defined yet"
end

##

assert 'Kernel#load exists' do
  assert_true Kernel.respond_to?(:load), "Kernel#load should exist"
end

assert 'Kernel#load with a relative file' do
  assert_defines :TEST_LOAD do
    in_fixture_dir { load 'load.rb' }
  end
end

assert "Kernel#load raises if the file can't be found" do
  begin
    in_fixture_dir { load 'missing.rb' }
  rescue LoadError => e
    assert_equal "cannot load such file -- `missing.rb`", e.message
  end
  assert_raise LoadError do
    in_fixture_dir { load 'another_missing.rb' }
  end
end

assert "$LOAD_PATH is an alias for $:" do
  assert_equal $LOAD_PATH, $:
end

assert "Kernel#load searches $LOAD_PATH, if no relative/absolute path" do
  in_fixture_dir do
    assert_raise LoadError do
      load 'load_path.rb'
    end
    $LOAD_PATH << File.join(Dir.getwd, 'load_path')
    assert_defines :TEST_LOAD_PATH do
      load 'load_path.rb'
    end
  end
end

assert 'Kernel#require exists' do
  skip "todo"
  assert_true Kernel.respond_to?(:require), "Kernel#require should exist"
end

assert 'Kernel#require_relative exists' do
  skip "todo"
  assert_true Kernel.respond_to?(:require_relative), "Kernel#require_relative should exist"
end
