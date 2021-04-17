require_relative "task"

module Msh
  module Tasks
    class Pkg < Task
      def setup!
        %w[
          pkg/usr/bin
          pkg/usr/share/man
        ].each { |dir| FileUtils.mkdir_p dir, verbose: true }
        sh "cp -r ./man/man* pkg/usr/share/man"
        sh "cp ./bin/msh pkg/usr/bin/"
        fpm(:deb) if `which apt` != ''
        fpm(:deb) if `which rpm` != ''
      end

      private

      def fpm type
        sh "fpm --output-type #{type}" \
           " --force" \
           " --version #{Msh::VERSION}" \
           " --license #{gem.license}" \
           " --maintainer #{gem.email}" \
           " --vendor #{gem.email}" \
           " --description '#{gem.summary}\n#{gem.description}'" \
           " --url #{gem.homepage}" \
           " --category shells" \
           " --name #{gem.name}" \
           " --package pkg/ -C pkg --input-type dir usr"
      end

      def gem
        Gem::Specification.find_by_name("msh")
      end
    end
  end
end

namespace :pkg do
  desc 'Build and install `.deb` package'
  task :deb => :pkg do
    sh "sudo apt install --reinstall ./pkg/msh_*.deb"
  end

  desc 'Build and install `.rpm` package'
  task :rpm do
    sh "rpm -U ./pkg/msh-*.rpm"
  end
end

Msh::Tasks::Pkg.new \
  "pkg",
  "Build `msh` into an installable package",
  :mruby, :man
