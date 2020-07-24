#!/usr/bin/env ruby
# vim: set filetype=ruby:

# Use CRuby here to test the MRuby executable

# TODO: https://github.com/aycabta/yamatanooroti/blob/master/test/yamatanooroti/test_multiplatform.rb

assert 'version' do
  assert_equal `msh --version`.strip, "msh version 0.3.0"
end
