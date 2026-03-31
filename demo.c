#include <string.h>
#include "sb3api.h"

int main() {
  const char str[32];
  while (!SB3_ask_str(str, "Enter a string: ", 32)) {}
  int length = strlen(str);
  SB3_say_dbl(length);
  return 0;
}
