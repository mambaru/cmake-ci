if ( CMAKE_BINARY_DIR STREQUAL CMAKE_SOURCE_DIR )
  message(FATAL_ERROR "********* FATAL: Source and build directories cannot be the same. ********* Remove CMakeCache.txt from ${CMAKE_SOURCE_DIR}")
endif()

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
               "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

if ( NOT CMAKE_CXX_STANDARD )
  set(CMAKE_CXX_STANDARD 11)
endif()

if ( NOT CMAKE_CXX_STANDARD_REQUIRED )
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

if ( NOT CMAKE_CXX_EXTENSIONS )
  set(CMAKE_CXX_EXTENSIONS OFF)
endif()

set(UNIT_TEST_BIN_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/tests")
set(UTIL_BIN_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/utils")

set(common_wci_properties
  ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/archive"
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/lib"
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

set(common_wci_libraries )
set(common_wci_options )
set(common_wci_definition )
set(common_wci_includes )

option(BUILD_SHARED_LIBS "Build the shared library" ON)
option(CODE_COVERAGE "Build with code coverage" OFF)
option(BUILD_TESTING "Build with tests and samples" OFF)
option(WITH_SAMPLES "Build with samples" ON)
option(PARANOID_WARNINGS "Paranoid warnings level" OFF)
option(EXTRA_WARNINGS "Extra warnings level" ON)
option(DISABLE_WARNINGS "Disable warnings" OFF)
option(NO_MEMCHECK "Disable all valgrind tests" OFF)

if (NOT BUILD_SHARED_LIBS)
  set(Boost_USE_STATIC_LIBS ON)
  set(Boost_USE_STATIC_RUNTIME ON)
  set(CMAKE_POSITION_INDEPENDENT_CODE OFF)
  if ( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" )
    list(APPEND common_wci_libraries -static-libgcc -static-libstdc++)
  endif()
else()
  set(Boost_USE_STATIC_LIBS OFF)
  set(Boost_USE_STATIC_RUNTIME OFF)
  if ( NOT CMAKE_POSITION_INDEPENDENT_CODE )
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
  endif()
endif()

if ( CODE_COVERAGE )
  set(BUILD_TESTING ON)
  set(WITH_SAMPLES OFF)
  set(CMAKE_BUILD_TYPE "Debug")
  list(APPEND common_wci_options -fprofile-arcs -ftest-coverage)
  list(APPEND common_wci_libraries -lgcov --coverage)
endif()

list(APPEND common_wci_options -ftemplate-depth=1024 -ftemplate-backtrace-limit=0)
list(APPEND common_wci_options $<$<CONFIG:Release>:-march=native>)
list(APPEND common_wci_options $<$<CONFIG:RelWithDebInfo>:-march=native>)
list(APPEND common_wci_definition $<$<CXX_COMPILER_ID:Clang>:__STRICT_ANSI__>)
#list(APPEND common_wci_options $<$<CXX_COMPILER_ID:Clang>:-stdlib=libc++>)

if ( CMAKE_CXX_STANDARD EQUAL 98 )
  option(DISABLE_LONG_LONG_98 "Disable long-long for 98" OFF)
  if ( DISABLE_LONG_LONG_98 )
    list(APPEND common_wci_definition -DDISABLE_LONG_LONG_98=ON)
  else()
    list(APPEND common_wci_definition -DDISABLE_LONG_LONG_98=OFF)
    list(APPEND common_wci_options -Wno-long-long)
  endif()
endif()

if ( NOT DISABLE_WARNINGS )
  list(APPEND common_wci_options -Wall -Werror)
  if ( EXTRA_WARNINGS OR PARANOID_WARNINGS)
    list(APPEND common_wci_options -Wextra -Wpedantic -Wformat -pedantic-errors)
    include(${CMAKE_CURRENT_LIST_DIR}/extended/extended.cmake)
  endif()
endif()

macro(wci_remove_options)
  list(REMOVE_ITEM common_wci_options ${ARGN})
endmacro(wci_remove_options)

macro(wci_add_options)
  list(APPEND common_wci_options ${ARGN})
  list(REMOVE_DUPLICATES common_wci_options)
endmacro(wci_add_options)

MACRO(wci_target_ target )
  target_compile_options(${target} PRIVATE ${common_wci_options})
  target_compile_definitions(${target} PRIVATE ${common_wci_definition})
  target_link_libraries(${target} PRIVATE ${common_wci_libraries})
  target_include_directories(${target} PRIVATE ${common_wci_includes})
  set_target_properties(${target} PROPERTIES ${common_wci_properties})
ENDMACRO(wci_target_)

MACRO(wci_util_ target )
  wci_target_(${target})
  set_target_properties(${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${UTIL_BIN_OUTPUT_DIR}")
ENDMACRO(wci_util_)

MACRO(wci_targets)
  foreach(arg IN ITEMS ${ARGN})
    wci_target_(${arg})
  endforeach()
ENDMACRO(wci_targets)

MACRO(wci_utils)
  foreach(arg IN ITEMS ${ARGN})
    wci_util_(${arg})
  endforeach()
ENDMACRO(wci_utils)

MACRO(wci_test)
  cmake_parse_arguments(args
    "NO_MEMCHECK"
    "NAME;TARGET;WORKING_DIRECTORY"
    "COMMAND;CONFIGURATIONS"
    ${ARGN}
  )

  if ( NOT args_NAME AND NOT args_TARGET)
    set(args_NAME "${ARGV0}")
  endif()

  if ( NOT args_COMMAND )
    set(args_COMMAND "${args_NAME}")
  endif()

  if ( NOT args_TARGET )
    set(args_TARGET "${args_COMMAND}")
  endif()

  if ( NOT args_NAME )
    set(args_NAME "${args_TARGET}")
  endif()

  if ( NOT args_WORKING_DIRECTORY )
    set(args_WORKING_DIRECTORY "${UNIT_TEST_BIN_OUTPUT_DIR}")
  endif()

  if ( TARGET ${args_TARGET} )
    wci_target_(${args_TARGET})
    set_target_properties(${args_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${args_WORKING_DIRECTORY}")
  endif()

  add_test(NAME ${args_NAME} COMMAND ${args_COMMAND} CONFIGURATIONS ${args_CONFIGURATIONS} WORKING_DIRECTORY ${args_WORKING_DIRECTORY})

  if ( NOT CODE_COVERAGE AND NOT args_NO_MEMCHECK AND NOT NO_MEMCHECK)
    add_test(
      NAME "${args_NAME}-memcheck"
      COMMAND valgrind --tool=memcheck --leak-check=full --error-exitcode=1 ${args_WORKING_DIRECTORY}/${args_COMMAND} ${args_UNPARSED_ARGUMENTS}
      WORKING_DIRECTORY ${args_WORKING_DIRECTORY}
    )
  endif()
ENDMACRO(wci_test)
