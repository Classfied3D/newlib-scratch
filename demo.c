#include <string.h>
#include <stdlib.h>
#include "sb3api.h"

int main() {
  const char str[32];
  while (!SB3_ask_str(str, "Enter a string: ", 32)) {}
  int length = strlen(str);
  SB3_say_dbl(length);
  SB3_wait(0.3);
  SB3_say_str("(fake) INITIALIZING...");
  SB3_wait(0.3);

  void* allocations[5];
  for (int i = 0; i < 5; i++) {
    double size;
    SB3_ask_dbl(&size, "How much to allocate?");
    void* addr = malloc((long)size);
    SB3_say_dbl((long)addr);
    SB3_wait(0.5);
  }

  for (int i = 0; i < 5; i++) {
    free(allocations[i]);
  }
  return 0;
}
