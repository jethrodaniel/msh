default:
	bundle exec rake -B mruby && du -hs msh
release:
	RELEASE=true bundle exec rake -B mruby && du -hs msh
