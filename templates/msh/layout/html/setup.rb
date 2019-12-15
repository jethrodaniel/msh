def init
  options.serializer.basepath = File.join(T('fulldoc').full_path, 'docs')

  T('fulldoc').run(options)
end
