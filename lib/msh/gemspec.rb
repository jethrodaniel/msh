# frozen_string_literal: true

require "pathname"

module Msh
  # Lazy way to not type all the stuff from the gemspec.
  #
  # @return [Gem::Specification] this gem's gemspec
  def self.gemspec
    @gemspec ||= Gem::Specification.find_by_name "msh"
  end

  # @return [Pathname] this gem's root directory path
  def self.root
    Pathname.new(__dir__) + "../.."
  end

  def self.man_dir
    root + "man"
  end
end
