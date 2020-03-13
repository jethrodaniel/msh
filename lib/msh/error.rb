# frozen_string_literal: true

module Msh
  class Error < StandardError
  end

  def self.debug?
    !ENV["MSH_DEBUG"].nil?
  end
end
