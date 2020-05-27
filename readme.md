# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)
[![docs](https://img.shields.io/badge/docs-1f425f.svg)](https://jethrodaniel.com/msh)
![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

**NOTE**: still in early stages, subject to breaking changes until `v1.0.0`.

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

## Installation

Assuming you have Ruby installed:

```
$ gem install msh
$ msh -h
```

Or download the prebuilt binaries to use via MRuby (todo).

## Roadmap

- [ ] version 1.0.0 - when I can use msh as my daily driver

## Development

See `rake -T` and tools in `./bin/`.

## Testing

```sh
$ bundle exec rake spec
```

Check out [the CI](https://github.com/jethrodaniel/msh/actions/) to see the specs' last executions 🔪.

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/jethrodaniel/msh).

```sh
git clone https://github.com/jethrodaniel/msh
cd msh && bundle && bundle exec rake
```

## License

MIT, see the [license file](license.txt).

## References

- [POSIX specifications](https://pubs.opengroup.org/onlinepubs/9699919799/)
