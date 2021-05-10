require_relative "task"
require "tempfile"

module Msh
  module Tasks
    class Consolidate < Task
      EXECUTABLE = 'bin/msh.rb'
      CLEAN << EXECUTABLE << 'bin'

      def setup!
        FileUtils.mkdir_p "bin"
        script = Tempfile.new
        script.puts <<~'BASH'
          set -ex

          cat <(echo '#!/usr/bin/env ruby') \
              <(gem consolidate msh) \
              <(echo 'Msh.start unless RUBY_ENGINE == "mruby"')
        BASH
        script.close
        sh "bash #{script.path} > #{EXECUTABLE}"
        sh "chmod u+x #{EXECUTABLE}"
      end
    end
  end
end

Msh::Tasks::Consolidate.new \
  "consolidate",
  "Compile a single-file `msh` script"
