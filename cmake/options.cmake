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

set(${PROJECT_NAME}_wci_options)
set(${PROJECT_NAME}_wci_definition)
set(${PROJECT_NAME}_wci_libraries)
set(${PROJECT_NAME}_wci_properties)
set(${PROJECT_NAME}_wci_includes)

set(UNIT_TEST_BIN_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/tests")
set(UTIL_BIN_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/utils")
set(EXAMPLES_BIN_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/examples")
set(BENCHMARKS_BIN_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/benchmarks")

if (NOT MSVC)
  include(${CMAKE_CURRENT_LIST_DIR}/ogenc.cmake)
endif()

list(APPEND ${PROJECT_NAME}_wci_properties
  ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/archive"
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/lib"
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

if ( NOT CMAKE_CXX_STANDARD )
  list(APPEND ${PROJECT_NAME}_wci_properties CXX_STANDARD 11)
  set(CMAKE_CXX_STANDARD 11 CACHE STRING "C++ Standard" FORCE)
else()
  list(APPEND ${PROJECT_NAME}_wci_properties CXX_STANDARD ${CMAKE_CXX_STANDARD})
endif()

if ( NOT CMAKE_CXX_STANDARD_REQUIRED )
  list(APPEND ${PROJECT_NAME}_wci_properties CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_STANDARD_REQUIRED ON CACHE STRING "C++ Standard requred" FORCE)
endif()

if ( NOT CMAKE_CXX_EXTENSIONS )
  list(APPEND ${PROJECT_NAME}_wci_properties CXX_EXTENSIONS OFF)
endif()

macro(env_option OPT_NAME TEXT VALUE)
  if (DEFINED ENV{${OPT_NAME}} AND NOT DEFINED ${OPT_NAME})
    set(${OPT_NAME} $ENV{${OPT_NAME}} CACHE STRING "${TEXT}" FORCE)
  else()
    option(${OPT_NAME} "${TEXT}" ${VALUE})
  endif()
endmacro()

env_option(BUILD_SHARED_LIBS "Create shared libraries" OFF)
#env_option(BUILD_SYSTEM_SHARED_LIBS "Create system shared libraries" OFF)
env_option(BUILD_TESTING "Build with tests and samples" OFF)
env_option(CODE_COVERAGE "Build with code coverage" OFF)
env_option(WITH_SAMPLES "Build with samples" ON)
env_option(NO_MEMCHECK "Disable all valgrind tests" OFF)
env_option(APOCALYPTIC_MODE "Do not disable test suite and paranoid warning mode for submodules" OFF)


if (NOT BUILD_SHARED_LIBS)
  set(Boost_USE_STATIC_LIBS ON)
  if ( NOT CMAKE_POSITION_INDEPENDENT_CODE)
    list(APPEND ${PROJECT_NAME}_wci_properties POSITION_INDEPENDENT_CODE OFF)
  endif()

  if ( NOT BUILD_SYSTEM_SHARED_LIBS )
    set(Boost_USE_STATIC_RUNTIME ON)
    if ( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" )
      list(APPEND ${PROJECT_NAME}_wci_libraries -static-libgcc -static-libstdc++)
    endif()
  endif()
else()
  set(Boost_USE_STATIC_LIBS OFF)
  set(Boost_USE_STATIC_RUNTIME OFF)
  if ( NOT CMAKE_POSITION_INDEPENDENT_CODE)
    list(APPEND ${PROJECT_NAME}_wci_properties POSITION_INDEPENDENT_CODE ON)
  endif()
endif()

if ( CODE_COVERAGE )
  set(BUILD_TESTING ON)
  set(CMAKE_BUILD_TYPE "Debug")
  if (NOT MSVC)
    list(APPEND ${PROJECT_NAME}_wci_options -fprofile-arcs -ftest-coverage)
    list(APPEND ${PROJECT_NAME}_wci_libraries -lgcov --coverage)
  endif()
endif()

if (NOT MSVC)
  list(APPEND ${PROJECT_NAME}_wci_options -ftemplate-depth=1024 -ftemplate-backtrace-limit=0)
  list(APPEND ${PROJECT_NAME}_wci_options $<$<CONFIG:Release>:-march=native>)
  list(APPEND ${PROJECT_NAME}_wci_options $<$<CONFIG:RelWithDebInfo>:-march=native>)
  list(APPEND ${PROJECT_NAME}_wci_definition $<$<CXX_COMPILER_ID:Clang>:__STRICT_ANSI__>)

  if ( CMAKE_CXX_STANDARD EQUAL 98 )
    option(DISABLE_LONG_LONG_98 "Disable long-long for 98" OFF)
    if ( DISABLE_LONG_LONG_98 )
      list(APPEND ${PROJECT_NAME}_wci_definition -DDISABLE_LONG_LONG_98=ON)
    else()
      list(APPEND ${PROJECT_NAME}_wci_definition -DDISABLE_LONG_LONG_98=OFF)
      list(APPEND ${PROJECT_NAME}_wci_options -Wno-long-long)
    endif()
  endif()
endif()

macro(wci_remove_options)
  cmake_parse_arguments(args "" "CONFIG" "" ${ARGN})
  if ( NOT args_CONFIG )
    if ( ${PROJECT_NAME}_wci_options)
      list(REMOVE_ITEM ${PROJECT_NAME}_wci_options ${ARGN})
    endif()
  else()
    foreach(arg IN ITEMS ${args_UNPARSED_ARGUMENTS})
      if ( ${PROJECT_NAME}_wci_options)
        list(REMOVE_ITEM ${PROJECT_NAME}_wci_options $<$<CONFIG:${args_CONFIG}>:${arg}>)
      endif()
    endforeach()
  endif()
endmacro(wci_remove_options)

macro(wci_add_options)
  cmake_parse_arguments(args "" "CONFIG" "" ${ARGN})
  if ( NOT args_CONFIG )
    list(APPEND ${PROJECT_NAME}_wci_options ${ARGN})
  else()
    foreach(arg IN ITEMS ${args_UNPARSED_ARGUMENTS})
      list(APPEND ${PROJECT_NAME}_wci_options $<$<CONFIG:${args_CONFIG}>:${arg}>)
    endforeach()
  endif()
  list(REMOVE_DUPLICATES ${PROJECT_NAME}_wci_options)
endmacro(wci_add_options)

if ( MSVC )
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

