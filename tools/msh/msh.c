#include <stdlib.h>
#include <stdio.h>

#include <mruby.h>
#include <mruby/array.h>

/* Start up MRuby, then exec our code.
 *
 * This is the same, more or less as
 *
 *     ./third_party/mruby/bin/mruby -r mrblib/mruby_main.rb -e '__main__([])'
 *
 * Adapted from https://github.com/hone/mruby-cli/blob/v0.0.4/tools/mruby-cli/mruby-cli.c
 */
int main(int argc, char *argv[])
{
  mrb_state *mrb = mrb_open();
  mrb_value ARGV = mrb_ary_new_capa(mrb, argc);
  int i, exit_code;

  for (i = 0; i < argc; i++)
    mrb_ary_push(mrb, ARGV, mrb_str_new_cstr(mrb, argv[i]));

  mrb_define_global_const(mrb, "ARGV", ARGV);

  mrb_funcall(mrb, mrb_top_self(mrb), "__main__", 0);

  exit_code = EXIT_SUCCESS;

  if (mrb->exc) {
    mrb_print_error(mrb);
    exit_code = EXIT_FAILURE;
  }
  mrb_close(mrb);

  return exit_code;
}
