# frozen_string_literal: true

# ruby -r mkmf ext/msh/extconf.rb
#
# See the source for docs: https://github.com/ruby/ruby/blob/master/lib/mkmf.rb

require "mkmf"
create_makefile "msh"

find_executable("bundle") || abort("'bundle' is required to install msh")

# find_executable("yarn") || abort("'yarn' is required to install msh docs")

require "pathname"
require "rake"

include Rake::FileUtilsExt

lib_dir = Pathname.new(__dir__) + '../..'

def rake cmd
  # sh "bundle exec rake --verbose -t #{cmd}"
  sh "bundle exec rake #{cmd}"
end

Dir.chdir lib_dir do
  sh "bundle install"
  rake "clean"
  rake "msh"
  rake "docs"
end
