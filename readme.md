# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)
![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

**NOTE**: not finished, breaking changes until `v1.0.0`, stay tuned.

**NOTE**: mruby redirection and pipes won't work until we get mruby to support `IO#reopen`

msh is a Ruby shell.

```
$ msh
Welcome to msh v0.4.0 (`?` for help)
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

See the main [manpage](man/msh.adoc).

## installation

Build everything

```
git clone --recursive https://github.com/jethrodaniel/msh
cd msh
bundle
bundle exec rake
```

At that point, you have the following executables

- `bin/msh` - single executable, uses MRuby
- `bin/msh.rb` - single ruby script

## development

```
bundle exec rake mruby
bundle exec rake test
```

We're using Github Actions to do that automatically - check out [the
CI](https://github.com/jethrodaniel/msh/actions/) to see the specs' lastest
executions 🔪.

## contributing

Please do.

Bug reports and pull requests are welcome on [GitHub](https://github.com/jethrodaniel/msh).

## license

MIT, see the [license file](license.txt).

## alternative shells

- https://github.com/bminor/bash
- https://github.com/zsh-users/zsh
- https://github.com/nushell/nushell
- https://github.com/fish-shell/fish-shell
- https://github.com/PowerShell/PowerShell
- https://elv.sh/
- https://github.com/dundalek/closh
- https://github.com/bsutton/dshell
