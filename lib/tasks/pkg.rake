namespace :pkg do
  g = Gem::Specification.find_by_name("msh")
  BIN_DIR    = "pkg/usr/bin".freeze
  MAN_DIR    = "pkg/usr/share/man".freeze
  MAINTAINER = g.email
  VERSION    = Msh::VERSION
  MSH        = File.join(BIN_DIR, "msh")
  MAN        = File.join(MAN_DIR, "man1/msh.1")
  DESC       = "#{g.summary}\n#{g.description}"
  URL        = g.homepage
  CATEGORY   = 'shells'
  LICENSE    = g.license

  directory BIN_DIR
  directory MAN_DIR

  file MSH => :mruby do
    sh "strip ./msh"
    sh "cp ./msh #{BIN_DIR}"
  end

  file MAN do
    sh "cp -r ./man/man* #{MAN_DIR}"
    sh "gzip -9 #{MAN_DIR}/**/*.[1-9]"
  end

  common =  " --force"
  common += " --version #{VERSION}"
  common += " --license #{LICENSE}"
  common += " --maintainer #{MAINTAINER}"
  common += " --vendor #{MAINTAINER}"
  common += " --description '#{DESC}'"
  common += " --url #{URL}"
  common += " --category #{CATEGORY}"

  %i[deb rpm].each do |type|
    task type => [BIN_DIR, MAN_DIR, MSH, MAN] do |t|
      sh "fpm --output-type #{type} #{common} --name msh --package pkg/ -C pkg --input-type dir usr"
    end
  end

  task :bin do
    sh "cp ./msh pkg/msh-#{VERSION}"
  end
  task :all => %i[deb rpm bin]

  namespace :deb do
    task :install do
      sh "sudo apt install ./pkg/msh_0.3.0_amd64.deb"
    end
  end
end
