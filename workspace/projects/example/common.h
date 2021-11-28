#ifndef COMMON_H_
#define COMMON_H_

#include <string>
namespace common {
namespace exception {

std::string getBacktrace();

void initialise();
} // namespace exception

namespace memory {
void initialise();
}

void initialise();
} // namespace common
#endif /*COMMON_H_*/
