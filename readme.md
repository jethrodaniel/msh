# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)
![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

**note**: nascent, breaking changes until `v1.0.0`, stay tuned.

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

## goals

- Use ruby in the shell
  - global interpolation
  - use ruby methods as functions and aliases
  - jump to the Ruby repl at any time
- Use less of the sh
  - restricted subset of sh/bash
- Be simple
- Be lightweight
  - packaged as a single binary via MRuby
- Be self-documenting

## installation

Msh is both a CRuby gem and a MRuby mgem.

Assuming you have CRuby installed:

```
$ gem install msh
$ msh -h
```

To build a binary with MRuby

```
git clone --recursive https://github.com/jethrodaniel/msh
cd msh
make release
```

Or download the prebuilt binaries for your platform from the [releases page](https://github.com/jethrodaniel/msh/releases) (see [the release action](.github/workflows/release.yml).

## roadmap

- [ ] environment variables
- [ ] local variables
- [ ] commands
- [ ] semi-colon separated commands
- [ ] conditional and
- [ ] conditional or
- [ ] pipes
- [ ] redirection
  - [ ] `[n]>`
  - [ ] `[n]>>`
  - [ ] `[n]<`
  - [ ] `&>`

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

- [POSIX specifications](https://pubs.opengroup.org/onlinepubs/9699919799/)

## alternatives

- https://github.com/bminor/bash
- https://github.com/zsh-users/zsh
- https://github.com/nushell/nushell
- https://github.com/fish-shell/fish-shell
- https://github.com/PowerShell/PowerShell
- https://elv.sh/
- https://github.com/dundalek/closh
