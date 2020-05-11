# frozen_string_literal: true

require "pathname"

module Msh
  # @return [Pathname] this gem's root directory path
  def self.root
    Pathname.new(__dir__) + "../.."
  end
end
