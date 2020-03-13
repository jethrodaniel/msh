# frozen_string_literal: true

require "msh/gemspec"

module Msh
  module Documentation
    # basic header stuff that all the manpages need
    #
    # @example
    #   = msh(1)
    #   <%= Msh::Documentation.prelude %>
    #
    #   == name
    #   ...
    def self.prelude
      <<~SH
        Copyright #{Time.now.strftime('%Y')}, #{Msh.gemspec.authors.join(',')} under the terms of the MIT license
        v#{Msh::VERSION}
        :doctype: manpage
        :release-version: #{Msh::VERSION}
        :man manual: Msh Manual
        :man source: Msh v#{Msh::VERSION}
        :man-linkstyle: pass:[blue R < >]
        :page-layout: base
      SH
    end
  end
end
