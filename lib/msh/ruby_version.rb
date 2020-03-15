# frozen_string_literal: true

module Msh
  class << self
    def ruby_2_4?
      ruby_version? 2.4
    end

    def ruby_2_5?
      ruby_version? 2.5
    end

    private

    def ruby_version? version
      (RUBY_VERSION.gsub(/[^\d]/, "")[0..2].to_i * 0.01 - version).abs < 0.1
    end
  end
end
