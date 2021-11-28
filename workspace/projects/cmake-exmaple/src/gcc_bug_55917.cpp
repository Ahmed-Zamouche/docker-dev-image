#include <stdexcept>
#include <thread>

void foo() { throw std::runtime_error("foo"); }

int main() {
  std::thread t(foo);
  t.join();
  return 0;
}
