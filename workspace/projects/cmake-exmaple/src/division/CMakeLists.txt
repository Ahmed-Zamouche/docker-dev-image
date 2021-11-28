cmake_minimum_required(VERSION 3.2)
project(division C CXX)

set(SOURCE_FILES
    division.h
    division.cpp
)

set(TEST_SOURCE_FILES
    test_division.cpp
)

add_library(division SHARED STATIC ${SOURCE_FILES})
install(TARGETS division DESTINATION ${PROJECT_INSTALL_LIB_DIR})
install(FILES division.h DESTINATION ${PROJECT_INSTALL_INCLUDE_DIR}/division)

add_executable(test_division ${TEST_SOURCE_FILES})
target_link_libraries(test_division division gtest_main gcov)
add_test(NAME test_c_division COMMAND test_division)
install(TARGETS test_division DESTINATION ${PROJECT_INSTALL_TEST_DIR})

