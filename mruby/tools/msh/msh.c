#include <stdlib.h>
#include <stdio.h>
#include <mruby.h>
#include <mruby/array.h>

// Entry point for the `msh` executable.
//
// Sets up MRuby and ARGV, then calls `__main__(ARGV)`.
//
int main(int argc, char **argv)
{
  mrb_state *mrb;
  mrb_value ARGV;
  int return_value;

  mrb = mrb_open();
  if (mrb == NULL) {
    fputs("Invalid MRuby interpreter, exiting `msh`", stderr);
    return EXIT_FAILURE;
  }

  ARGV = mrb_ary_new_capa(mrb, argc);
  for (int i = 1; i < argc; i++) {
    char* utf8 = mrb_utf8_from_locale(argv[i], -1);
    if (utf8) {
      mrb_ary_push(mrb, ARGV, mrb_str_new_cstr(mrb, utf8));
      mrb_utf8_free(utf8);
    }
  }
  mrb_define_global_const(mrb, "ARGV", ARGV);

  mrb_funcall(mrb, mrb_top_self(mrb), "__main__", 1, ARGV);

  return_value = EXIT_SUCCESS;
  if (mrb->exc) {
    mrb_print_error(mrb);
    return_value = EXIT_FAILURE;
  }
  mrb_close(mrb);

  return return_value;
}
