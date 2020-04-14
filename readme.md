# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)
![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

msh is a ruby shell.

Its goal is the same as that of Ruby

> Ruby is designed to make programmers happy.
>
> Yukihiro 'Matz' Matsumoto


**NOTE**: still in early stages, subject to breaking changes until `v1.0.0`.

## supported rubies

- [x] CRuby >= 2.5
- [ ] JRuby

## dependencies

### runtime

- [readline](https://github.com/ruby/readline-ext/) (C, comes with CRuby)

### build

- [asciidoctor](https://github.com/asciidoctor/asciidoctor) to build the manpages

## installation

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

## roadmap

- [ ] version 1.0.0 will be when I can use msh as my daily driver
- [ ] version 2.0.0 may be a mruby port, in order to package as a static executable (maybe)

## development

see the rakefile

```sh
$ bundle exec rake -T
rake build              # Build msh-0.1.0.gem into the pkg directory
rake clean              # Remove any temporary products
rake clobber            # Remove any generated files
rake install            # Build and install msh-0.1.0.gem into system gems
rake install:local      # Build and install msh-0.1.0.gem into system gems without network access
rake lint               # Run RuboCop
rake lint:auto_correct  # Auto-correct RuboCop offenses
rake man                # generate the man pages
rake man:check          # verify man pages are in sync
rake msh                # build everything
rake readme             # generates readme.md from ERB
rake release[remote]    # Create tag v0.1.0 and build and push msh-0.1.0.gem to TODO: Set to 'https://rubygems.org'
rake run                # build everything and run msh
rake spec               # Run RSpec code examples
rake spec:examples      # create sample msh scripts from spec/examples.yaml
rake spec:help          # dump results from `help` builtin to text files for specs
```

Run `./bin/console` to load up msh in a REPL.

### testing

msh has more tests than you can shake a stick at.

Most of these come from a [single YAML file](./spec/fixtures/examples.yml)...

```yml
:examples:
  # words, filenames, options, etc

  "echo such wow":
    :valid: true
    :tokens: |
      ["[1:1-4][WORD, 'echo']",
       "[1:6-9][WORD, 'such']",
       "[1:11-13][WORD, 'wow']",
       "[1:14-14][EOF, '']"]
    :ast: |
      s(:EXPR,
        s(:COMMAND,
          s(:WORD, "echo"),
          s(:WORD, "such"),
          s(:WORD, "wow")))

  "echo so scare":
...
```

and are `eval`'d during the specs.

```sh
$ bundle exec rake spec
```

You can also check out [the CI](https://github.com/jethrodaniel/msh/actions/) to see the specs' last executions 🔪.

## contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/jethrodaniel/msh).

```sh
git clone https://github.com/jethrodaniel/msh
cd msh && bundle exec rake
```

## license

```sh
The MIT License (MIT)

Copyright (c) 2020 Mark Delk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

## references

- [POSIX specifications](https://pubs.opengroup.org/onlinepubs/9699919799/)
- [shell intro (1978)](https://web.archive.org/web/20170207130846/http://porkmail.org/era/unix/shell.html)
- [bashish BNF](https://github.com/jalanb/jab/blob/master/src/bash/bash.bnf)

## thanks

We stand on the shoulders of giants, to whom we are grateful.

- https://craftinginterpreters.com/
- Crystal lang's source code for real-world examples of lexer/parser/interperter/compiler design
