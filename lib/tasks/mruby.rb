require_relative "task"
require_relative "consolidate"

module Msh
  module Tasks
    class MRuby < Task
      EXECUTABLE = 'third_party/mruby/build/host/bin/msh'
      CLEAN << EXECUTABLE << 'mruby/mrblib' << 'bin'

      def setup!
        mkdir_p "./mruby/mrblib/"
        cp Consolidate::EXECUTABLE, "./mruby/mrblib/"

        mruby_rake :all, :test

        sh "strip #{EXECUTABLE}"

        mkdir_p "bin"
        cp EXECUTABLE, "bin/"

        msh "echo hi there, the time is now #{Time.now}"
      end

      private

      # Run rake commands in the MRuby source code directory
      #
      def mruby_rake *tasks
        Dir.chdir "third_party/mruby" do
          sh "MRUBY_CONFIG=../../mruby/build_config.rb " \
             "rake " \
             "#{tasks.join(' ')}"
        end
      end

      # Run commands using the msh binary
      #
      def msh cmd
        sh "./bin/msh -c '#{cmd}'"
      end
    end
  end
end

Msh::Tasks::MRuby.new \
  "mruby",
  "Build `msh` binary using MRuby",
  :consolidate
