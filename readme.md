# msh

![](https://github.com/jethrodaniel/msh/workflows/ci/badge.svg)
![](https://img.shields.io/github/license/jethrodaniel/msh.svg)
[![docs](https://img.shields.io/badge/docs-1f425f.svg)](https://jethrodaniel.com/msh)
![](https://img.shields.io/github/stars/jethrodaniel/msh?style=social)

msh is a ruby shell.

Its goal is the same as Ruby

> Ruby is designed to make programmers happy.
>
> Yukihiro 'Matz' Matsumoto

## installation

Assuming you have Ruby installed:

```
$ gem install msh
$ msh -h
Usage: msh <command> [options]... [file]...

msh is a ruby shell

To file issues or contribute, see https://github.com/jethrodaniel/msh.

commands:
    lexer                            run the lexer
    parser                           run the parser
    <blank>                          run the interpreter

options:
    -h, --help                       print this help
    -V, --version                    show the version
        --copyright, --license       show the copyright
```

## what it do

```msh
echo "#{Time.now}" | cowsay
```

Configuration is in `~/.config/msh/config.rb`

```ruby
Msh.configure do |c|
  c.color = true
  c.history = {:size => 10.megabytes}
end
```

## development

see the rakefile

```sh
$ bundle exec rake -T
rake build              # Build msh-0.1.0.gem into the pkg directory
rake clean              # Remove any temporary products
rake clobber            # Remove any generated files
rake docs               # generate the docs/
rake install            # Build and install msh-0.1.0.gem into system gems
rake install:local      # Build and install msh-0.1.0.gem into system gems without network access
rake lint               # Run RuboCop
rake lint:auto_correct  # Auto-correct RuboCop offenses
rake msh                # build everything
rake release[remote]    # Create tag v0.1.0 and build and push msh-0.1.0.gem to TODO: Set to 'http://mygemserver.com'
rake run                # build everything and run msh
rake spec               # Run RSpec code examples
```

### testing

msh has more tests than you can shake a stick at.

Most of these come from a [single YAML file](./spec/fixtures/examples.yml)...

```yml
:examples:
  #
  # pipes
  #
  "fortune | cowsay":
    :valid: true
    :tokens: |
      [[:WORD, "fortune"],
       [:PIPE, "|"],
       [:WORD, "cowsay"]]
    :ast: |
      s(:EXPR,
        s(:PIPELINE,
          s(:COMMAND,
            s(:WORD, "fortune")),
          s(:COMMAND,
            s(:WORD, "cowsay"))))

...
```

and are `eval`'d during the specs.

```sh
$ bundle exec rake spec
```

You can also check out [the CI](https://github.com/jethrodaniel/msh/actions/) to see the specs' last executions 🔪.

## docs

Documentation is available at https://jethrodaniel.com/msh/Msh.html.

## contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/jethrodaniel/msh).

```sh
git clone https://github.com/jethrodaniel/msh
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

- [ruby](https://github.com/ruby/ruby/)
- [racc](https://github.com/ruby/racc)
- [rexical](https://github.com/tenderlove/rexical)
- [reline](https://github.com/ruby/reline)
- [yard](https://github.com/lsegal/yard)
- [POSIX specifications](https://pubs.opengroup.org/onlinepubs/9699919799/)
- [shell intro (1978)](https://web.archive.org/web/20170207130846/http://porkmail.org/era/unix/shell.html)
- [bashish BNF](https://github.com/jalanb/jab/blob/master/src/bash/bash.bnf)
