# frozen_string_literal: true

require "pathname"

module Msh
  NAME     = "msh"
  AUTHORS  = ["Mark Delk"].freeze
  EMAIL    = ["jethrodaniel@gmail.com"].freeze
  SUMMARY  = "a ruby shell"
  HOMEPAGE = "https://github.com/jethrodaniel/msh"
  LICENSE  = "MIT"

  # @return [Pathname] this gem's root directory path
  def self.root
    Pathname.new(__dir__) + "../.."
  end
end
