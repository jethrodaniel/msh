# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)

![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

**NOTE**: still in early stages, subject to breaking changes until `v1.0.0`.

msh is a Ruby shell.

```
$ echo π is #{Math::PI} | cowsay
 ________________________
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
Usage:
    msh [options]... [file]...

Options:
    -h, --help                       print this help
    -V, --version                    show the version   (0.1.0)
        --copyright, --license       show the copyright (MIT)
    -c  <cmd_string>                 runs <cmd_string> as shell input

```

## Roadmap

- [ ] version 1.0.0 - when I can use msh as my daily driver

## Development

See `rake -T` and tools in `./bin/`.

## Testing

msh has more tests than you can shake a stick at.

Most of these come from a [single YAML file](./spec/fixtures/examples.yml)(1600 lines)...

```yml
  #
  # multiple expressions
  #

  "echo a; echo b; echo c":
    :lexer_valid: true
    :parser_valid: true
    :interpreter_valid: true
    :tokens: |
      ['[1:1-4][WORD, "echo"]',
       '[1:5-5][SPACE, " "]',
       '[1:6-6][WORD, "a"]',
       '[1:7-7][SEMI, ";"]',
       '[1:8-8][SPACE, " "]',
       '[1:9-12][WORD, "echo"]',
       '[1:13-13][SPACE, " "]',
       '[1:14-14][WORD, "b"]',
       '[1:15-15][SEMI, ";"]',
       '[1:16-16][SPACE, " "]',
       '[1:17-20][WORD, "echo"]',
       '[1:21-21][SPACE, " "]',
       '[1:22-22][WORD, "c"]',
       '[1:23-23][EOF, "\u0000"]']
    :ast: |
      s(:PROG,
        s(:EXPR,
          s(:CMD,
            s(:WORD,
              s(:LIT, "echo")),
            s(:WORD,
              s(:LIT, "a")))),
        s(:EXPR,
          s(:CMD,
            s(:WORD,
              s(:LIT, "echo")),
            s(:WORD,
              s(:LIT, "b")))),
        s(:EXPR,
          s(:CMD,
            s(:WORD,
              s(:LIT, "echo")),
            s(:WORD,
              s(:LIT, "c")))))
    :exit_code: 0
    :output: |
      a
      b
      c
    :error: |


...
```

and are `eval`'d (😱) during the specs.

```sh
$ bundle exec rake spec
```

You can also check out [the CI](https://github.com/jethrodaniel/msh/actions/) to see the specs' last executions 🔪.

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
