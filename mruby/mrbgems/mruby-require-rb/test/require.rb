def in_fixture_dir
  Dir.chdir File.join(File.dirname(__FILE__), 'fixtures') do
    yield
  end
end

assert 'load' do
  assert_true Kernel.respond_to?(:load), "Kernel#load should exist"
  assert_false Object.const_defined?(:TEST_LOAD), "TEST_LOAD should not exist"

  in_fixture_dir do
    load 'load.rb'
  end

  assert_true Object.const_defined?(:TEST_LOAD), "TEST_LOAD should exist"
end

# assert 'require' do
#   assert_true Kernel.respond_to?(:require), "Kernel#require exists"
# end

# assert 'require_relative' do
#   assert_true Kernel.respond_to?(:require), "Kernel#require_relative exists"
# end
