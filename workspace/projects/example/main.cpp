#include "common.h"
#include "printf/printf.h"
#include <chrono>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <thread>

int baz() {
  std::cout << "Backrace:" << std::endl
            << common::exception::getBacktrace() << std::endl;
  return 1;
}

int bar() { return baz(); }

int foo() { return bar(); }

volatile void *ptr{nullptr};

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;

  common::initialise();

  std::cout << "Hello World!" << std::endl;

  foo();

  void *ptr0 = malloc(1023);
  std::cout << "Allocated    : 1023 bytes @" << ptr0 << std::endl;

  void *ptr1 = malloc(2047);
  std::cout << "Allocated    : 2047 bytes @" << ptr1 << std::endl;

  void *ptr2 = realloc(ptr0, 4095);
  std::cout << "Re-allocated : 4095 bytes @" << ptr2 << std::endl;

  // free(ptr0);
  // std::cout << "Freed        : 1023 bytes @" << ptr1 << std::endl;

  free(ptr2);
  std::cout << "Freed        : 4095 bytes @" << ptr2 << std::endl;

  free(ptr1);
  std::cout << "Freed       : 2047 bytes @" << ptr1 << std::endl;

  return 0;
}
