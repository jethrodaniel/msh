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

  file MSH => [:mruby, BIN_DIR] do
    sh "strip ./msh"
    sh "cp ./msh #{BIN_DIR}"
  end

  file MAN => MAN_DIR do
    sh "cp -r ./man/man* #{MAN_DIR}"
    sh "gzip -9 #{MAN_DIR}/**/*.[1-9]"
  end

  opts =  " --force"
  opts += " --version #{VERSION}"
  opts += " --license #{LICENSE}"
  opts += " --maintainer #{MAINTAINER}"
  opts += " --vendor #{MAINTAINER}"
  opts += " --description '#{DESC}'"
  opts += " --url #{URL}"
  opts += " --category #{CATEGORY}"

  %i[deb rpm].each do |type|
    task type => [BIN_DIR, MAN_DIR, MSH, MAN] do |t|
      sh "fpm --output-type #{type} #{opts} --name msh --package pkg/ -C pkg --input-type dir usr"
    end
  end

  task :bin do
    sh "cp ./msh pkg/msh-#{VERSION}"
  end
  task :all => %i[deb rpm bin]

  namespace :install do
    task :deb do
      sh "sudo apt install ./pkg/msh_*.deb"
    end

    task :rpm do
      sh "rpm -U ./pkg/msh-*.rpm"
    end
  end
end
