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

#Сбрасываем свойства
set(common_wci_options)
set(common_wci_definition)
set(common_wci_libraries)
set(common_wci_properties)
set(common_wci_includes )

set(UNIT_TEST_BIN_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/tests")
set(UTIL_BIN_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/utils")

list(APPEND common_wci_properties
  ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/archive"
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/lib"
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

if ( NOT CMAKE_CXX_STANDARD )
  list(APPEND common_wci_properties CXX_STANDARD 11)
else()
  list(APPEND common_wci_properties CXX_STANDARD ${CMAKE_CXX_STANDARD})
endif()

if ( NOT CMAKE_CXX_STANDARD_REQUIRED )
  list(APPEND common_wci_properties CXX_STANDARD_REQUIRED ON)
endif()

if ( NOT CMAKE_CXX_EXTENSIONS )
  list(APPEND common_wci_properties CXX_EXTENSIONS OFF)
endif()

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
  list(APPEND common_wci_properties POSITION_INDEPENDENT_CODE OFF)
  if ( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" )
    list(APPEND common_wci_libraries -static-libgcc -static-libstdc++)
  endif()
else()
  set(Boost_USE_STATIC_LIBS OFF)
  set(Boost_USE_STATIC_RUNTIME OFF)
  list(APPEND common_wci_properties POSITION_INDEPENDENT_CODE ON)
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
  cmake_parse_arguments(args "" "CONFIG" "" ${ARGN})
  if ( NOT args_CONFIG )
    list(REMOVE_ITEM common_wci_options ${ARGN})
  else()
    foreach(arg IN ITEMS ${args_UNPARSED_ARGUMENTS})
      list(REMOVE_ITEM common_wci_options $<$<CONFIG:${args_CONFIG}>:${arg}>)
    endforeach()
  endif()

endmacro(wci_remove_options)

macro(wci_add_options)
  cmake_parse_arguments(args "" "CONFIG" "" ${ARGN})
  if ( NOT args_CONFIG )
    list(APPEND common_wci_options ${ARGN})
  else()
    foreach(arg IN ITEMS ${args_UNPARSED_ARGUMENTS})
      list(APPEND common_wci_options $<$<CONFIG:${args_CONFIG}>:${arg}>)
    endforeach()
  endif()
  list(REMOVE_DUPLICATES common_wci_options)
endmacro(wci_add_options)
