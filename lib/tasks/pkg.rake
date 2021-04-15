namespace :pkg do
  g = Gem::Specification.find_by_name("msh")
  bin_dir    = "pkg/usr/bin".freeze
  man_dir    = "pkg/usr/share/man".freeze
  maintainer = g.email
  msh        = File.join(bin_dir, "msh")
  man        = File.join(man_dir, "man1/msh.1")
  desc       = "#{g.summary}\n#{g.description}".freeze
  url        = g.homepage
  category   = "shells".freeze
  license    = g.license

  directory bin_dir
  directory man_dir

  file msh => [:mruby, bin_dir] do
    sh "strip ./msh"
    sh "cp ./msh #{bin_dir}"
  end

  file man => man_dir do
    sh "cp -r ./man/man* #{man_dir}"
    # sh "gzip -9 #{man_dir}/**/*.[1-9]"
  end

  opts =  " --force"
  opts += " --version #{Msh::VERSION}"
  opts += " --license #{license}"
  opts += " --maintainer #{maintainer}"
  opts += " --vendor #{maintainer}"
  opts += " --description '#{desc}'"
  opts += " --url #{url}"
  opts += " --category #{category}"

  %i[deb rpm].each do |type|
    task type => [bin_dir, man_dir, msh, man] do |_t|
      sh "fpm --output-type #{type} #{opts} --name msh --package pkg/ -C pkg --input-type dir usr"
    end
  end

  CLEAN << "pkg"

  namespace :install do
    task :deb do
      sh "sudo apt install ./pkg/msh_*.deb"
    end

    task :rpm do
      sh "rpm -U ./pkg/msh-*.rpm"
    end
  end
end
