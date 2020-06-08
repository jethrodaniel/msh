# frozen_string_literal: true

task :bench do
  Dir.glob("benchmark/*.rb").each do |b|
    sh "benchmark-driver -r memory --repeat-count 5 -v --bundler #{b}"
    sh "benchmark-driver -r ips --repeat-count 5 -v --bundler #{b}"
  end
end
