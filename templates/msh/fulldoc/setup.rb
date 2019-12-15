# frozen_string_literal: true

require "msh"
require "rake"

# This method is called by Yard to create the output
include ::Rake::FileUtilsExt
def init
  case @format
  when :html
    handle_html
  when :text
    handle_text
  else
    raise "expected format of :text or :html"
  end

  # p process(YARD::Registry.root)
end

def process node, level = 0
  puts "#{' ' * level}-> #{node}"

  node.children.map { |c| process c, level + 1 } if node.respond_to? :children
  true
end

def handle_text
  Templates::Engine.with_serializer("msh.txt", options.serializer) do
    erb :index
  end
end

def handle_html
  # output app.js for
  app_src = "#{T('fulldoc').full_path}/app.js.erb"
  app_out = app_src.delete_suffix ".erb"
  File.open(app_out, "w") { |f| f.puts ERB.new(File.read(app_src)).result(binding) }

  sh_in_src "yarn"
  sh_in_src "./node_modules/.bin/webpack app.js"

  %w[
    dist/bundle.js
    dist/bundle.js.map
    index.erb
  ].each { |file| out file }

  # t = Dir.glob("#{T('fulldoc').full_path}/**/*")
  #    .select { |f| File.file? f }
  #    .map { |f| f.delete_prefix "#{T('fulldoc').full_path}/" }
  #    .reject { |f| f.start_with? "node_modules" }
end

# ---

def out f
  out_name = f.gsub(".erb", ".html")
  if f.end_with? ".erb"
    options.serializer.serialize out_name, erb(f.delete_suffix(".erb"))
  else
    options.serializer.serialize out_name, file(f)
  end
end

def sh_in_src cmd
  sh_in_dir cmd, T("fulldoc").full_path
end

def sh_in_dir cmd, dir
  Dir.chdir(dir) { ::Rake.sh cmd }
end

def serialize files
  files.each do |f|
    content = file(f)
    options.serializer.serialize f, content
  end
end
