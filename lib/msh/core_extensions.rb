class Object
  def self.delegate meth, obj, via: nil
    define_method meth do
      send(obj).send(via || meth)
    end
  end
end
