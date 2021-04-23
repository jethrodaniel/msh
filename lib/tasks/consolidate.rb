require_relative "task"

module Msh
  module Tasks
    class Consolidate < Task
      EXECUTABLE = 'bin/msh.rb'
      CLEAN << EXECUTABLE << 'bin'

      def setup!
        FileUtils.mkdir_p "bin"
        sh "bundle exec gem consolidate lib/msh.rb " \
           "--no-stdlib " \
           "--footer='Msh.start unless RUBY_ENGINE == \"mruby\"' " \
           "--header='#!/usr/bin/env ruby'" \
           "> #{EXECUTABLE}"
        sh "chmod u+x #{EXECUTABLE}"
      end
    end
  end
end

Msh::Tasks::Consolidate.new \
  "consolidate",
  "Compile a single-file `msh` script"
