cmake_minimum_required(VERSION 3.2)

project(cmake-project-template)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")

set (CMAKE_CXX_FLAGS_DEBUG "-O1 ${CMAKE_CXX_FLAGS_DEBUG} -fno-omit-frame-pointer -fno-optimize-sibling-calls -fsanitize=address,undefined")
set (CMAKE_LINKER_FLAGS_DEBUG "${CMAKE_LINKER_FLAGS_DEBUG} -fno-omit-frame-pointer -fno-optimize-sibling-calls -fsanitize=address,undefined")

set(CMAKE_INSTALL_PREFIX ${PROJECT_SOURCE_DIR}/.local)
set(PROJECT_INSTALL_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/.local/include)
set(PROJECT_INSTALL_BIN_DIR ${PROJECT_SOURCE_DIR}/.local/bin)
set(PROJECT_INSTALL_TEST_DIR ${PROJECT_SOURCE_DIR}/.local/test)
set(PROJECT_INSTALL_LIB_DIR ${PROJECT_SOURCE_DIR}/.local/lib)

include_directories(${PROJECT_INSTALL_INCLUDE_DIR})

include(cmake/gtest.cmake)
include(cmake/gcov.cmake)
include(cmake/cppcheck.cmake)
include(cmake/clang-format.cmake)
add_subdirectory(src)

