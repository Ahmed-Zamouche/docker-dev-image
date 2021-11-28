cmake_minimum_required(VERSION 3.2)
project(divider)

add_subdirectory(division)
#set(SOURCE_FILES divider.cpp gcc_bug_55917.cpp)

add_executable(divider divider.cpp)
target_link_libraries(divider division)
install(TARGETS divider DESTINATION ${DIVISIBLE_INSTALL_BIN_DIR})

add_executable(gcc_bug_55917 gcc_bug_55917.cpp)
target_link_libraries(gcc_bug_55917 pthread)
install(TARGETS gcc_bug_55917 DESTINATION ${DIVISIBLE_INSTALL_BIN_DIR})
