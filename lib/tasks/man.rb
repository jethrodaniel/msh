require_relative "task"

require "asciidoctor"
require "erb"

require 'yamatanooroti'

class MshMainManpageExample
  include Yamatanooroti::VTermTestCaseModule

  def run
    start_terminal 24, 80, './bin/msh'
    write "echo π ≈ \#{Math::PI}\n"
    write "echo \#{self}\n"
    write "repl\n"
    write "def prompt = 'λ '\n"
    write "def hi name; puts \"hello, there \#{name}\"; end\n"
    write ""
    write "hi y'all\n"
    close
    "$ msh\n#{output}"
  end

  private

  def output
    result.select { |line| line != "" }.join("\n")
  end
end

module Msh
  module Tasks
    class Man < Task
      CLEAN << 'man/man1'

      def setup!
        mkdir_p "man/man1"

        Dir.glob("man/*.adoc").each do |adoc|
          create_manpage!(adoc)
        end

        create_readme!
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

      def create_readme!
        File.open('readme.adoc', 'w') do |f|
          f.puts <<~T
            ![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
            ![](https://img.shields.io/github/license/jethrodaniel/msh.svg)
            ![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

            **NOTE**: not finished, breaking changes until `v1.0.0`, stay tuned.

          T
          f.puts erb('man/msh.adoc')
        end
        puts "-> readme.adoc"
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
