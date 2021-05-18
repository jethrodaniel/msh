require_relative "task"

require "asciidoctor"
require "erb"

module Msh
  module Tasks
    class Man < Task
      CLEAN << 'man/man1'

      def setup!
        mkdir_p "man/man1"

        Dir.glob("man/*.adoc").each do |adoc|
          create_manpage!(adoc)
        end
      end

      private

      def create_manpage! adoc
        cmd = File.basename(adoc, File.extname(adoc))
        Asciidoctor.convert(
          manpage_for(adoc),
          :to_dir  => "man/man1/",
          :to_file => "#{cmd}.1",
          :doctype => "manpage",
          :backend => "manpage",
        )
        puts "-> man/man1/#{cmd}.1"
        sh "gzip -vf man/man1/#{cmd}.1"
      end

      def manpage_for adoc
        <<~MAN
          = #{File.basename(adoc)}(1)
          :doctype: manpage
          :release-version: #{Msh::VERSION}
          :manmanual: Msh Manual
          :mansource: Msh v#{Msh::VERSION}

          #{erb(adoc)}

          == msh

          Part of msh(1).
        MAN
      end

      def erb file
        puts "erb -> #{file}"
        ERB.new(File.read(file)).result(binding)
      end
    end
  end
end

namespace :man do
  task :install => :man do
    sh "sudo cp -rav man/man1/* /usr/share/man/man1/"
  end
end

Msh::Tasks::Man.new \
  "man",
  "Generate manpages"
