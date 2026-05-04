#include <string.h>
#include <stdlib.h>
#include "sb3api.h"

int main() {
  const char str[32];
  while (!SB3_ask_str(str, "Enter a string: ", 32)) {}
  int length = strlen(str);
  SB3_say_dbl(length);

  void* lol = malloc(941);
  SB3_say_dbl((long)lol);
  free(lol);
  return 0;
}
