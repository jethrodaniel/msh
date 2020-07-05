# vim/peg

Syntax highlighting for peg input files.

Adapted from `racc.vim` in vim's [source code.](https://github.com/vim/vim/blob/master/runtime/syntax/racc.vim)

## install

If using vim8's plugin manager, copy this directory to your `pack/start`

```
mkdir -p ~/.vim/pack/peg/start
cp -ra peg/vim ~/.vim/pack/peg/start/peg
```

Otherwise, copy these files to your `syntax/` and `ftdetect/` directories.

```
cp vim/ftdetect/peg.vim ~/.vim/ftdetect/
cp vim/syntax/peg.vim ~/.vim/syntax/
```

## usage

The `ftdetect` should ensure `.peg` files use this syntax highlighting.

Additionally, you may find the following modeline useful

```
# vim: set filetype=peg
```
