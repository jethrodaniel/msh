# frozen_string_literal: true

# Backports for Ruby 2.4

module Msh
  # TODO: possible refinements?
  #
  # module Extensions
  #   refine String do
  #   end
  # end
end

class String
  def delete_prefix prefix
    sub(/\A#{prefix}/, "")
  end

  def delete_suffix suffix
    sub(/#{suffix}\z/, "")
  end
end

class Array
  def prepend element
    [element] + self
  end
end

class Pathname
  def glob path
    Dir.glob "#{self}/#{path}"
  end
end

class Binding
  def source_location
    [
      eval("__FILE__", binding, __FILE__, __LINE__),
      eval("__LINE__", binding, __FILE__, __LINE__)
    ]
  end
end
