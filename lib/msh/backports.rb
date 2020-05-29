# frozen_string_literal: true

# Backports for nice things.

version = RUBY_VERSION[0..2].to_f

if version <= 2.7
  ENV.instance_eval do
    if RUBY_ENGINE == "mruby"
      def merge! hsh
        hsh.each { |k, v| ENV[k] = v }
      end
    else
      alias merge! update
    end
  end
end

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

  class Symbol
    def start_with? prefix
      to_s.start_with? prefix
    end
  end
end
