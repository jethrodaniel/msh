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

if version <= 2.5
  class String
    def delete_suffix suffix
      self[0..size - suffix.size - 1]
    end
  end

  class Pathname
    def glob glob
      Dir.glob(glob)
    end
  end

  class Array
    alias prepend unshift
  end
end
