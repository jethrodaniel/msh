# frozen_string_literal: true

require "yard"
require "asciidoctor"

YARD::Registry.clear
YARD::Registry.load!

def create_manpage cmd, man_src
  man = <<~MAN
    = #{cmd}(1)
    :doctype: manpage
    :release-version: #{Msh::VERSION}
    :man manual: Msh Manual
    :man source: Msh v#{Msh::VERSION}
    :page-layout: base

    #{man_src}

    == msh

    Part of msh(1).
  MAN

  Asciidoctor.convert(
    man,
    :to_dir => "man/man1/",
    :to_file => "#{cmd}.1",
    :doctype => "manpage",
    :backend => "manpage"
  )
end

YARD::Registry.load_all

BUILTIN_CMDS = Dir.glob("lib/msh/builtins/*")
                  .map { |f| File.basename(f, ".rb") }
                  .reject do |cmd|
                    YARD::Registry.at("Msh::Env##{cmd}")&.docstring == ""
                  end

BUILTIN_FILES = BUILTIN_CMDS.map { |cmd| "man/man1/msh-#{cmd}.1" }

desc "generate the man pages"
task :man => ["man:msh", *BUILTIN_FILES.map(&:to_s), "man:dump_help_for_specs"]

namespace :man do
  task :msh do
    puts "-> man/man1/msh.1"
    create_manpage :msh, YARD::Registry.at("Msh").docstring
  end

  BUILTIN_CMDS.each do |cmd|
    file "man/man1/msh-#{cmd}.1" do
      puts "-> man/man1/msh-#{cmd}.1"
      create_manpage "msh-#{cmd}", YARD::Registry.at("Msh::Env##{cmd}").docstring
    end
  end

  # stolen from bundler with love:
  #   - https://github.com/rubygems/bundler/blob/788a4071cf4e0b42f83e25ba2aedaf0b63546866/Rakefile#L138
  desc "verify man pages are in sync"
  task :check => :man do
    sh "git diff --quiet --ignore-all-space man" do |outcome, _|
      if outcome
        puts "\nManpages are in sync!\n"
      else
        sh "GIT_PAGER=cat git diff --ignore-all-space man"

        puts "\nMan pages are out of sync. " \
             "Above you can see the diff that got generated from " \
             "rebuilding them. " \
             "Please review and commit the results.\n"

        exit 1
      end
    end
  end

  desc "dump results from `help` builtin to text files for specs"
  task :dump_help_for_specs => %i[install] do
    (BUILTIN_CMDS + ["msh"]).each do |topic|
      # help with no args is just `man msh`
      cmd = topic == "msh" ? "help" : "help #{topic}"

      require_relative "../../spec/spec_helper"
      with_80_columns do
        sh "2>&1 MANPAGER=cat msh -c '#{cmd}' > spec/fixtures/help/#{topic}.txt"
      end
    end
  end
end
