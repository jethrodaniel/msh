# man

Documentation for msh is produced from AsciiDoc documents, generated using [Asciidoctor](https://github.com/asciidoctor/asciidoctor).

## adding/updating the docs

The main rakefile in the project root dir has a task to run erb and asciidoctor
on any `.adoc.erb` files in this directory.

Run `rake man:check` to ensure the manpages are up-to-date.

To see the manpages as they would look when installed, check out [the help specs](../spec/fixtures/help/).

## References

- https://asciidoctor.org/docs/user-manual/#man-pages
