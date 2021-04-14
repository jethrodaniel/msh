require_relative "task"

module Msh
  module Tasks
    class MRuby < Task
      EXECUTABLE = 'third_party/mruby/bin/msh'
      CLEAN << EXECUTABLE << 'mruby/mrblib' << 'bin'

      def setup!
        FileUtils.mkdir_p "./mruby/mrblib/"
        FileUtils.cp Consolidate::EXECUTABLE, "./mruby/mrblib/", verbose: true

        mruby_rake :clean, :all

        sh "strip -s -R .comment -R .gnu.version " \
           "--strip-unneeded #{EXECUTABLE}"

        FileUtils.mkdir_p "bin"
        FileUtils.cp EXECUTABLE, "bin/", verbose: true
      end

      private

      # Run rake commands in the MRuby source code directory
      #
      def mruby_rake(*tasks)
        sh "MRUBY_CONFIG=./mruby/build_config.rb rake " \
           "-f third_party/mruby/Rakefile " \
           "#{tasks.join(' ')}"
      end
    end
  end
end

Msh::Tasks::MRuby.new \
  "mruby",
  "Build `msh` binary using MRuby",
  :consolidate
