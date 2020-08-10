# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)
![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

**NOTE**: not finished, breaking changes until `v1.0.0`, stay tuned.

**NOTE**: mruby redirection and pipes won't work until we get mruby to support `IO#reopen`

msh is a Ruby shell.

```
$ msh
Welcome to msh v0.3.0 (`?` for help)
~/msh λ echo pi is #{Math::PI} | cowsay
 _________________________
< pi is 3.141592653589793 >
 -------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
~/msh λ repl
enter some ruby (sorry, no multiline)
> def upcase; ARGF.each_line { |l| puts l.upcase }; end
=> :upcase
> def prompt; "% "; end
=> :prompt
^D
% fortune | upcase
LIVE IN A WORLD OF YOUR OWN, BUT ALWAYS WELCOME VISITORS.
```

See the main [manpage](man/msh.1.adoc).

## installation

Msh is available (in order of preference) as

- `deb` and `rpm` packages via `rake pkg:all`
- a single Ruby script (`make; ruby mrblib/msh.rb`)
- a Ruby gem (`gem install msh` once this is pushed, clone and `rake` until then)

Check out the [releases page](https://github.com/jethrodaniel/msh/releases) for pre-built packages.
## development

```
git clone --recursive https://github.com/jethrodaniel/msh
```

See `rake -T` and tools in `./bin/`.

Check out [the CI](https://github.com/jethrodaniel/msh/actions/) to see the specs' lastest executions 🔪.

## verification

`ssh512` checksums are in the `certs` directory. See `rake checksums`.

## contributing

Please do.

Bug reports and pull requests are welcome on [GitHub](https://github.com/jethrodaniel/msh).

## license

MIT, see the [license file](license.txt).

## some alternative shells

- https://github.com/bminor/bash
- https://github.com/zsh-users/zsh
- https://github.com/nushell/nushell
- https://github.com/fish-shell/fish-shell
- https://github.com/PowerShell/PowerShell
- https://elv.sh/
- https://github.com/dundalek/closh
- https://github.com/bsutton/dshell
