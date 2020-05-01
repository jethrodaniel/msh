# frozen_string_literal: true

# Backports for nice things.

version = RUBY_VERSION[0..2].to_f

if version <= 2.6
  class Binding
    def source_location
      self.eval "[__FILE__, __LINE__]"
    end
  end
end
