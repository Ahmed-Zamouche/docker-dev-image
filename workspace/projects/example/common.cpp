#include "common.h"
#include "printf/printf.h"
#include <atomic>
#include <cassert>
#include <climits>
#include <csignal>
#include <cstdlib>
#include <cstring>
#include <execinfo.h>
#include <iomanip>
#include <iostream>
//#include <memory>
#include <mutex>
#include <sstream>
#include <string>
#include <unistd.h>
#include <utility>

#ifndef __USE_GNU
#define __USE_GNU
#endif /*__USE_GNU*/
#include <ucontext.h>

#include <unordered_map>
#include <unordered_set>

#ifdef NDEBUG
#define PRINTF(...)
#else
#define PRINTF printf
#endif

extern "C" void *__libc_malloc(size_t size);
extern "C" void __libc_free(void *ptr);
extern "C" void *__libc_calloc(size_t nmemb, size_t size);
extern "C" void *__libc_realloc(void *ptr, size_t size);
extern "C" void *__libc_aligned_alloc(size_t alignment, size_t size);
extern "C" int __libc_posix_memalign(void **memptr, size_t alignment,
                                     size_t size);
extern "C" void *__libc_reallocarray(void *ptr, size_t nmemb, size_t size);

class Mutex {
  std::atomic_flag m_flag = ATOMIC_FLAG_INIT;

public:
  Mutex() = default;
  virtual ~Mutex() = default;

  Mutex(const Mutex &) = delete;
  Mutex &operator=(const Mutex &) = delete;

  void lock() {
    while (m_flag.test_and_set(std::memory_order_acquire))
      ;
  }
  void unlock() { m_flag.clear(std::memory_order_release); }
};

void _putchar(char ch) { write(STDERR_FILENO, &ch, 1); }

namespace common {
constexpr int HEX_DIGIT_BITS = 4;
std::string ptr2str(const void *ptr) {
  std::ostringstream oss;
  oss << std::internal << std::hex << std::setfill('0')
      << std::setw(sizeof(void *) * CHAR_BIT / HEX_DIGIT_BITS) << ptr;
  return oss.str();
}
namespace exception {
std::string getBacktrace() {

  int size = 64;
  while (1) {
    void *addrs[size];
    int num = backtrace(addrs, size);
    if (num < size) {
      char **symbols = backtrace_symbols(&addrs[0], num);
      if (symbols) {
        std::ostringstream oss;
        for (int i = 0; i < num; i++) {
          oss << ptr2str(addrs[i]) << ": " << symbols[i] << std::endl;
        }
        free(symbols);
        return oss.str();
      }
    }
    size *= 2;
  }
  return "????";
}

void writeBacktrace(int fd = 1) {

  int size = 64;
  while (1) {
    void *addrs[size];
    int num = backtrace(addrs, size);
    if (num < size) {
      printf("Backtrace:\n");
      backtrace_symbols_fd(&addrs[0], num, fd);
      return;
    }
    size *= 2;
  }
}

volatile sig_atomic_t signal_status = 0;

void signalHandler(int num, siginfo_t *info, void * /*ucontext*/) {
  printf("Terminated by signal: %s , singno=%d, code=%d, errno=%d\n",
         strsignal(num), info->si_signo, info->si_code, info->si_errno);
  writeBacktrace(STDERR_FILENO);
  // if (num == SIGABRT)
  { std::_Exit(EXIT_FAILURE); }

  struct sigaction sa {};
  sa.sa_handler = SIG_DFL;
  sigemptyset(&sa.sa_mask);
  sigaction(num, &sa, NULL);
  signal_status = num;
  raise(num);
  return;
}

void registerSignalHandler() {
  struct sigaction sa;

  sa.sa_sigaction = signalHandler;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART | SA_SIGINFO;

  const int SIGNALS[] = {
      SIGHUP,  SIGINT,  SIGQUIT, SIGILL,    SIGTRAP, SIGABRT,  SIGBUS,
      SIGFPE,  SIGKILL, SIGUSR1, SIGSEGV,   SIGUSR2, SIGPIPE,  SIGALRM,
      SIGTERM, SIGCHLD, SIGCONT, SIGSTOP,   SIGTSTP, SIGTTIN,  SIGTTOU,
      SIGURG,  SIGXCPU, SIGXFSZ, SIGVTALRM, SIGPROF, SIGWINCH, SIGSYS};
  for (auto &&SIGNAL : SIGNALS) {
    sigaction(SIGNAL, &sa, NULL);
  }
}
void initialise() { registerSignalHandler(); }
void deinitialise() {}
} // namespace exception

namespace memory {

static std::atomic<int> alloc_hook_disabled{1};
static thread_local int malloc_call_count{0};
static thread_local int free_call_count{0};
static thread_local int calloc_call_count{0};
static thread_local int realloc_call_count{0};
// static thread_local int aligned_alloc_call_count{0};
// static thread_local int posix_memalign_call_count{0};

struct AllocInfo {
  void *ptr{nullptr};
  size_t size{0};
  void *caller{nullptr};
  bool freed{false};
};

using Key = void *;
using Value = AllocInfo;
static std::unordered_map<Key, Value> _alloc_map{};
static std::recursive_mutex _alloc_mutex;

void snprint_alloc_info(char *str, size_t n, const AllocInfo &ai) {
  snprintf(str, n, "{ptr: %p, size: %5zu, caller: %p, freed: %d}", ai.ptr,
           ai.size, ai.caller, ai.freed);
}
void print_alloc_info_map() {
  char buffer[128];
  printf("Allocation: [\n");
  for (auto &&alloc : _alloc_map) {
    snprint_alloc_info(buffer, sizeof(buffer), alloc.second);
    printf("%s\n", buffer);
  }
  printf("]\n");
}

void *malloc(size_t size, void *caller) {
  PRINTF("malloc(size: %zu, caller: %p)\n", size, caller);
  // deactivate hooks for logging
  malloc_call_count++;
  void *ptr = size > 0 ? ::malloc(size) : nullptr;
  // do logging
  if (ptr) {
    const std::lock_guard<decltype(_alloc_mutex)> lock(_alloc_mutex);
    auto it = _alloc_map.find(ptr);
    if (it != _alloc_map.end()) {
      if (not it->second.freed) {
        alloc_hook_disabled = 1;
        printf("malloc(): double alloc detected for ptr: %p\n", it->second.ptr);
        print_alloc_info_map();
        exit(EXIT_FAILURE);
      } else {
        it->second.size = size;
        it->second.caller = caller;
        it->second.freed = false;
      }
    } else {
      _alloc_map.insert({ptr, AllocInfo{ptr, size, caller}});
    }
  }
  // reactivate hooks
  malloc_call_count--;
  return ptr;
}

void free(void *ptr, void *caller) {
  // backtrace_symbols_fd(&caller, 1, 1);
  (void)caller;
  PRINTF("free(ptr: %p, caller: %p)\n", ptr, caller);
  // deactivate hooks for logging
  free_call_count++;
  ::free(ptr);
  // do logging
  if (ptr) {
    const std::lock_guard<decltype(_alloc_mutex)> lock(_alloc_mutex);
    auto it = _alloc_map.find(ptr);
    if (it != _alloc_map.end()) {
      if (it->second.freed) {
        alloc_hook_disabled = 1;
        printf("free(): double free detected for ptr: %p", it->second.ptr);
        print_alloc_info_map();
        exit(EXIT_FAILURE);
      } else {
        // it->second.caller = caller;
        it->second.freed = true;
      }
    }
  }
  // reactivate hooks
  free_call_count--;
}

void *calloc(size_t nmemb, size_t size, void *caller) {
  PRINTF("calloc(nmemb: %zu, size: %zu, caller: %p)\n", nmemb, size, caller);
  // deactivate hooks for logging
  calloc_call_count++;
  void *ptr = ::calloc(nmemb, size);
  // do logging
  if (ptr) {
    const std::lock_guard<decltype(_alloc_mutex)> lock(_alloc_mutex);
    auto it = _alloc_map.find(ptr);
    if (it != _alloc_map.end()) {
      if (not it->second.freed) {
        alloc_hook_disabled = 1;
        printf("calloc(): double alloc detected for ptr: %p", it->second.ptr);
        print_alloc_info_map();
        exit(EXIT_FAILURE);
      } else {
        it->second.size = nmemb * size;
        it->second.caller = caller;
        it->second.freed = false;
      }
    } else {
      _alloc_map.insert({ptr, AllocInfo{ptr, size, caller}});
    }
  }
  // reactivate hooks
  calloc_call_count--;
  return ptr;
}

void *realloc(void *ptr, size_t size, void *caller) {
  PRINTF("realloc(ptr: %p, size: %zu, caller: %p)\n", ptr, size, caller);
  // deactivate hooks for logging
  realloc_call_count--;
  void *newptr = ::realloc(ptr, size);
  // do logging
  if (newptr) {
    const std::lock_guard<decltype(_alloc_mutex)> lock(_alloc_mutex);
    {
      auto it = _alloc_map.find(newptr);
      if (it != _alloc_map.end()) {
        if (it->second.freed /*&& newptr != ptr*/) {
          alloc_hook_disabled = 1;
          printf("realloc(): double alloc detected for ptr %p", it->second.ptr);
          print_alloc_info_map();
          exit(EXIT_FAILURE);
        } else {
          it->second.size = size;
          it->second.caller = caller;
          it->second.freed = false;
        }
      } else {
        _alloc_map.insert({newptr, AllocInfo{newptr, size, caller}});
      }
    }
    {
      auto it = _alloc_map.find(ptr);
      (void)it;
    }
  }
  // reactivate hooks
  realloc_call_count--;
  return newptr;
}

#if 0
int posix_memalign(void **memptr, size_t alignment, size_t size,
                   void * /*caller*/) {
  // deactivate hooks for logging
  posix_memalign_call_count++;
  int res = __libc_posix_memalign(memptr, alignment, size);
  // do logging
  // reactivate hooks
  posix_memalign_call_count--;
  return res;
}
void *aligned_alloc(size_t alignment, size_t size, void *caller) {
  (void)caller;
  PRINTF("aligned_alloc(alignment: %zu, size: %zu, caller: %p)\n", __func__,
         __LINE__, alignment, size, caller);

  // deactivate hooks for logging
  aligned_alloc_call_count++;
  void *ptr = __libc_aligned_alloc(alignment, size);
  // do logging
  // reactivate hooks
  aligned_alloc_call_count--;
  return ptr;
}
#endif

void initialise() { alloc_hook_disabled = 0; }
void deinitialise() { alloc_hook_disabled = 1; }
} // namespace memory

void deinitialise() {
  memory::deinitialise();
  exception::deinitialise();
}

void atexit() {
  deinitialise();
  if (exception::signal_status != 0) {
    printf("SignalValue: %d\n", exception::signal_status);
  }
  memory::print_alloc_info_map();
}

void initialise() {
  if (::atexit(common::atexit) != 0) {
    std::cerr << "atexit(): function registration failed" << std::endl;
    exit(EXIT_FAILURE);
  }
  exception::initialise();
  memory::initialise();
}
} // namespace common

void *malloc(size_t size) {
  PRINTF("malloc(size: %zu)\n", size);
  if (size == 0) {
    return nullptr;
  }
  void *caller = __builtin_return_address(0);
  void *ptr = (common::memory::malloc_call_count == 0 &&
               !common::memory::alloc_hook_disabled)
                  ? common::memory::malloc(size, caller)
                  : __libc_malloc(size);
  PRINTF("malloc(size: %zu): %p\n", size, ptr);
  return ptr;
}

void free(void *ptr) {
  PRINTF("free(ptr: %p)\n", ptr);
  if (ptr == nullptr) {
    return;
  }
  void *caller = __builtin_return_address(0);
  if (common::memory::free_call_count == 0 &&
      !common::memory::alloc_hook_disabled)
    common::memory::free(ptr, caller);
  else
    __libc_free(ptr);
}

void *calloc(size_t nmemb, size_t size) {
  PRINTF("calloc(nmemb: %zu, size: %zu)\n", nmemb, size);
  if (nmemb == 0 || size == 0) {
    return nullptr;
  }
  void *caller = __builtin_return_address(0);
  void *ptr = (common::memory::calloc_call_count)
                  ? common::memory::calloc(nmemb, size, caller)
                  : __libc_calloc(nmemb, size);
  PRINTF("calloc(nmemb: %zu, size: %zu): %p\n", nmemb, size, ptr);
  return ptr;
}

void *realloc(void *ptr, size_t size) {
  PRINTF("realloc(ptr: %p, size: %zu)\n", ptr, size);
  if (ptr == nullptr && size == 0) {
    return nullptr;
  }
  void *caller = __builtin_return_address(0);
  void *newptr = (common::memory::realloc_call_count == 0 &&
                  !common::memory::alloc_hook_disabled)
                     ? common::memory::realloc(ptr, size, caller)
                     : __libc_realloc(ptr, size);
  PRINTF("realloc(ptr: %p, size: %zu): %p\n", ptr, size, newptr);
  return newptr;
}

#if 0
int posix_memalign(void **memptr, size_t alignment, size_t size) {
  void *caller = __builtin_return_address(0);
  return (common::memory::posix_memalign_call_count == 0 && !common::memory::alloc_hook_disabled)
             ? common::memory::posix_memalign(memptr, alignment, size, caller)
             : __libc_posix_memalign(memptr, alignment, size);
}

void *aligned_alloc(size_t alignment, size_t size) {
  PRINTF("aligned_alloc(alignment: %zu, size: %zu)\n", alignment, size);
  void *caller = __builtin_return_address(0);
  void *ptr = (common::memory::aligned_alloc_call_count == 0 &&
               !common::memory::alloc_hook_disabled)
                  ? common::memory::aligned_alloc(alignment, size, caller)
                  : __libc_aligned_alloc(alignment, size);
  PRINTF("aligned_alloc(alignment: %zu, size: %zu): %p\n", alignment, size,
         ptr);
  return ptr;
}
#endif
