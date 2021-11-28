# additional target to perform clang-format run, requires clang-format

set (EXCLUDE_DIR "/cmake-exmaple/build/")

# get all project files
file(GLOB_RECURSE ALL_SOURCE_FILES *.cpp *.h)

foreach (SOURCE_FILE ${ALL_SOURCE_FILES})
  string(FIND ${SOURCE_FILE} ${EXCLUDE_DIR} EXCLUDE_DIR_FOUND)
  if (NOT ${EXCLUDE_DIR_FOUND} EQUAL -1)
    list(REMOVE_ITEM ALL_SOURCE_FILES ${SOURCE_FILE})
  endif ()
endforeach ()

add_custom_target(
  clang_format
  COMMAND /usr/bin/clang-format
  -style=Google
  -i
  ${ALL_SOURCE_FILES}
)
