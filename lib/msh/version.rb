module Msh
  VERSION = "0.4.0".freeze

  patch_lvl = "p#{RUBY_PATCHLEVEL}" if Object.const_defined?(:RUBY_PATCHLEVEL)
  VERSION_STRING = "msh v#{Msh::VERSION} running on " \
                   "#{RUBY_ENGINE} v#{RUBY_VERSION}#{patch_lvl}".freeze
end
