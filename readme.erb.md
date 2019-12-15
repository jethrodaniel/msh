# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)
[![docs](https://img.shields.io/badge/docs-1f425f.svg)](https://jethrodaniel.com/msh)
![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

msh is a ruby shell.

Its goal is the same as Ruby

> Ruby is designed to make programmers happy.
>
> Yukihiro 'Matz' Matsumoto

## installation

Assuming you have Ruby installed:

```
$ gem install msh
$ msh -h
<%= `msh -h` %>
```

## what it do

```msh
echo "#{Time.now}" | cowsay
```

Configuration is in `~/.config/msh/config.rb`

```ruby
Msh.configure do |c|
  c.color = true
  c.history = {:size => 10.megabytes}
end
```

## development

see the rakefile

```sh
$ bundle exec rake -T
<%= `bundle exec rake -T` %>
```

### testing

msh has more tests than you can shake a stick at.

Most of these come from a [single YAML file](./spec/fixtures/examples.yml)...

```yml
<%= `sed -n '5,22p' spec/fixtures/examples.yml` %>
...
```

and are `eval`'d during the specs.

```sh
$ bundle exec rake spec
```

You can also check out [the CI](https://github.com/jethrodaniel/msh/actions/) to see the specs' last executions 🔪.

## docs

Documentation is available at https://jethrodaniel.com/msh/Msh.html.

## contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/jethrodaniel/msh).

```sh
git clone https://github.com/jethrodaniel/msh
```

## license

```sh
<%= `msh --copyright` %>
```

## references

- [ruby](https://github.com/ruby/ruby/)
- [racc](https://github.com/ruby/racc)
- [rexical](https://github.com/tenderlove/rexical)
- [reline](https://github.com/ruby/reline)
- [yard](https://github.com/lsegal/yard)
- [POSIX specifications](https://pubs.opengroup.org/onlinepubs/9699919799/)
- [shell intro (1978)](https://web.archive.org/web/20170207130846/http://porkmail.org/era/unix/shell.html)
- [bashish BNF](https://github.com/jalanb/jab/blob/master/src/bash/bash.bnf)
