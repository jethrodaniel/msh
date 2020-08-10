directory "certs"

CHECKSUMS = "certs/msh.sha512"

task :checksums => "checksums:dump"

namespace :checksums do
  task :dump => CHECKSUMS

  file CHECKSUMS do |t|
    Dir.chdir("pkg") do
      sh "sha512sum msh* > ../#{t.name}"
    end
  end
end
