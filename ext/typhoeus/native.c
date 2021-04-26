#include <native.h>

VALUE mTyphoeus;

void Init_native()
{
  mTyphoeus = rb_const_get(rb_cObject, rb_intern("Xingfus"));

  init_typhoeus_easy();
  init_typhoeus_multi();
  init_typhoeus_form();
}
