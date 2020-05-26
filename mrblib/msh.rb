#!/usr/bin/env ruby
# frozen_string_literal: true

def __main__ _argv
  puts "hi"

  require "./lib/msh/version"

  puts "msh #{Msh::VERSION}"
end
