# addional target to perform cppcheck run, requires cppcheck

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
  cppcheck
  COMMAND /usr/local/bin/cppcheck
  --enable=warning,performance,portability,information,missingInclude
  --language=c++
  --std=c++17
  --library=qt.cfg
  --template="[{severity}][{id}] {message} {callstack} \(On {file}:{line}\)"
  --verbose
  --quiet
  #  --check-config
  ${ALL_SOURCE_FILES}
)
