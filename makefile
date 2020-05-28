default:
	bundle exec rake mruby && du -hs msh
release:
	RELEASE=true bundle exec rake mruby && du -hs msh
