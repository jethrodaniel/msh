# Backports for nice things.

ENV.instance_eval do
  def merge! hsh
    hsh.each { |k, v| ENV[k] = v }
  end

  # For some reason, `alias` doesn't work here in MRuby
  # alias merge! update
  def update hsh
    merge! hsh
  end
end unless ENV.respond_to?(:merge!) && ENV.respond_to?(:update)


# version = RUBY_VERSION[0..2].to_f

# if version <= 2.6
#   class Binding
#     def source_location
#       self.eval "[__FILE__, __LINE__]"
#     end
#   end
# end

# if version <= 2.5
#   class String
#     def delete_suffix suffix
#       self[0..size - suffix.size - 1]
#     end
#   end

#   class Pathname
#     def glob glob
#       Dir.glob(glob)
#     end
#   end

#   class Array
#     alias prepend unshift
#   end

#   class Symbol
#     def start_with? prefix
#       to_s.start_with? prefix
#     end
#   end
# end
