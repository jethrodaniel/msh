# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)
![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

**note**: not finished, breaking changes until `v1.0.0`, stay tuned.

msh is a Ruby shell.

```
$ echo π is #{Math::PI} | cowsay
< π is 3.141592653589793 >
 ------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

See the main [manpage](man/msh.1.adoc).

## installation

Msh is both a CRuby gem and a MRuby mgem.

```
$ gem install msh # cruby
$ make release    # mruby
```

Make sure you `git clone --recursive` or run `git submodule update`, since MRuby is a submodule.

Or (todo) download the prebuilt binaries for your platform from the [releases page](https://github.com/jethrodaniel/msh/releases) (see [the release action](.github/workflows/release.yml)).

## development

See `rake -T` and tools in `./bin/`.

```sh
$ bundle exec rake spec # cruby
$ make                  # mruby
```

Check out [the CI](https://github.com/jethrodaniel/msh/actions/) to see the specs' last executions 🔪.

### mruby

Differences

```
# without the parens, we get `warning: '*' interpreted as argument prefix`
Kernel.puts(*objs)
```

Lack of `IO#reopen`, `IO#fcntl`, `Binding`, etc...

## contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/jethrodaniel/msh).

```sh
git clone --recursive https://github.com/jethrodaniel/msh
cd msh
bundle && bundle exec rake
make
```

## license

MIT, see the [license file](license.txt).

## references

- [POSIX sh specifications](https://pubs.opengroup.org/onlinepubs/9699919799/)

Sh alternatives

- https://github.com/bminor/bash
- https://github.com/zsh-users/zsh
- https://github.com/nushell/nushell
- https://github.com/fish-shell/fish-shell
- https://github.com/PowerShell/PowerShell
- https://elv.sh/
- https://github.com/dundalek/closh
- https://github.com/bsutton/dshell
