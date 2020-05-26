#include <stdlib.h>
#include <stdio.h>

#include <mruby.h>
#include <mruby/array.h>
#include <mruby/version.h>
#include <mruby/variable.h>

/* Based/copied from
 *
 * https://github.com/hone/mruby-cli/blob/v0.0.4/tools/mruby-cli/mruby-cli.c
 */
int main(int argc, char *argv[])
{
  mrb_state *mrb = mrb_open();
  mrb_value ARGV = mrb_ary_new_capa(mrb, argc);
  int i, exit_code;

  for (i = 0; i < argc; i++)
    mrb_ary_push(mrb, ARGV, mrb_str_new_cstr(mrb, argv[i]));

  mrb_define_global_const(mrb, "ARGV", ARGV);
  mrb_define_global_const(mrb, "RUBY_ENGINE", "mruby");

  // call __main__(ARGV)
  mrb_funcall(mrb, mrb_top_self(mrb), "__main__", 1, ARGV);

  exit_code = EXIT_SUCCESS;

  if (mrb->exc) {
    mrb_print_error(mrb);
    exit_code = EXIT_FAILURE;
  }
  mrb_close(mrb);

  return exit_code;
}
