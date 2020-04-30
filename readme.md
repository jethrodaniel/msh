# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)
![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

msh is a ruby shell.

**NOTE**: still in early stages, subject to breaking changes until `v1.0.0`.

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
  # words, filenames, options, etc
  #

  "echo such wow":
    :lexer_valid: true
    :parser_valid: true
    :interpreter_valid: false
    :exit_code: 0
    :tokens: |
      ['[1:1-4][WORD, "echo"]',
       '[1:5-5][SPACE, " "]',
       '[1:6-9][WORD, "such"]',
       '[1:10-10][SPACE, " "]',
       '[1:11-13][WORD, "wow"]',
       '[1:14-14][EOF, "\\u0000"]']
    :ast: |
      s(:EXPR,
        s(:COMMAND,
          s(:WORD,
            s(:LITERAL, "echo")),
          s(:WORD,
            s(:LITERAL, "such")),
          s(:WORD,
            s(:LITERAL, "wow"))))
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
- [shell intro (1978)](https://web.archive.org/web/20170207130846/http://porkmail.org/era/unix/shell.html)
- [bashish BNF](https://github.com/jalanb/jab/blob/master/src/bash/bash.bnf)

We stand on the shoulders of giants, to whom we are grateful.

- https://craftinginterpreters.com/
- https://ycpcs.github.io/cs340-fall2016/lectures/lecture05.html
- https://github.com/crystal-lang/crystal
- https://github.com/ruby/ruby
