# frozen_string_literal: true

class Object
  # Stupid simple method delegation, only supporting no args.
  #
  #     A = Struct.new(:foo) do
  #       delegate :hi, :foo
  #     end
  #
  #     class Foo
  #       def hi
  #         __method__
  #       end
  #     end
  #
  #     A.new(Foo.new).hi #=> :hi
  #
  def self.delegate meth, obj, via: nil
    define_method meth do
      send(obj).send(via || meth)
    end
  end
end
