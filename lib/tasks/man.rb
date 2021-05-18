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

        create_readme!
        create_license!

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

      def create_readme!
        File.open('readme.adoc', 'w') do |f|
          f.puts <<~T
            image:https://github.com/jethrodaniel/msh/workflows/ci/badge.svg[]
            image:https://img.shields.io/github/license/jethrodaniel/msh.svg[]
            image:https://img.shields.io/github/stars/jethrodaniel/msh?style=social[]

            **NOTE**: not finished, breaking changes until `v1.0.0`, stay tuned.

          T
          f.puts erb('man/msh.adoc')
        end
        puts "-> readme.adoc"
      end

      def create_license!
        File.open('license.txt', 'w') do |f|
          f.puts <<~T
            The MIT License (MIT)

            Copyright (c) #{Time.now.year} #{`git config --global --get user.name`}

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in
            all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
            THE SOFTWARE.
          T
        end
        puts "-> license.txt"
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
