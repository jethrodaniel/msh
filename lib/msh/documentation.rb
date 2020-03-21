# frozen_string_literal: true

require "msh/gemspec"
require "msh/version"

module Msh
  module Documentation
    # basic header stuff that all the manpages need
    def self.prelude
      <<~SH
        Copyright #{Time.now.strftime('%Y')}, #{Msh::AUTHORS.join(',')} under the terms of the MIT license
        v#{Msh::VERSION}
        :doctype: manpage
        :release-version: #{Msh::VERSION}
        :man manual: Msh Manual
        :man source: Msh v#{Msh::VERSION}
        :page-layout: base
      SH
    end
  end
end
