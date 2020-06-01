# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)
![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

**note**: still nascent, breaking changes until `v1.0.0`, stay tuned.

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
## Goals

- Use ruby in the shell
  - global interpolation
  - use ruby methods as functions and aliases
  - jump to the Ruby repl at any time
- Use less of the sh
  - restricted subset of sh/bash
- Be simple
- Be lightweight
  - packaged as a single binary
- Be self-documenting

## Installation

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

Or download the prebuilt binaries for your platform from the [releases page](https://github.com/jethrodaniel/msh/releases).


## Roadmap

- [ ] version 1.0.0 - when I can use msh as my daily driver

## Development

See `rake -T` and tools in `./bin/`.

## Testing

```sh
$ bundle exec rake spec
$ make
```

Check out [the CI](https://github.com/jethrodaniel/msh/actions/) to see the specs' last executions 🔪.

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/jethrodaniel/msh).

```sh
git clone --recursive https://github.com/jethrodaniel/msh
cd msh
bundle && bundle exec rake
make
```

## License

MIT, see the [license file](license.txt).

## References

- [POSIX specifications](https://pubs.opengroup.org/onlinepubs/9699919799/)

## Alternatives

i.e, alternative shells. If there's a _legit_ shell out there that chooses to
be something more than a `sh/bash/zsh` clone, feel free to add it here.

- https://github.com/nushell/nushell
- https://github.com/fish-shell/fish-shell
- https://github.com/PowerShell/PowerShell
