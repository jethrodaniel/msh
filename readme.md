# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)

![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)



**NOTE**: still in early stages, subject to breaking changes until `v1.0.0`.

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

Use ruby in the shell

- global interpolation
- use ruby methods as functions, aliases, and in interpolation
- use ruby variables for environment variables

Be as simple and understandable as possible, while doing as much as possible
without external dependencies.

- dependencies should be lightweight, with no gem extensions

## Dependencies

💯 percent Ruby, no C dependencies. Only 2 runtime dependencies

- [ast](https://github.com/whitequark/ast)
- [paint](https://github.com/janlelis/paint)

## Installation

Assuming you have Ruby installed:

```
$ gem install msh
$ msh -h
a ruby shell

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
- [ ] version 2.0.0 - may be a mruby port, in order to package as a static executable

## Development

```
$ bundle exec rake -T     # `rake install` to install locally
$ bundle exec bin/console # load Msh up in a Ruby REPL
$ bundle exec bin/lexer   # Run the lexer
$ bundle exec bin/parser  # Run the parser
$ bundle exec exe/msh     # Run Msh
$ bundle exec yard server --reload # View documentation in a browser
```

## Testing

msh has more tests than you can shake a stick at.

Most of these come from a [single YAML file](./spec/fixtures/examples.yml)...

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

and are `eval`'d during the specs.

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

## Thanks

Special thanks to [crafting interpreters](https://craftinginterpreters.com/) -
go read it if you're the least bit interested in how lexers, parsers, and interpreters operate.
