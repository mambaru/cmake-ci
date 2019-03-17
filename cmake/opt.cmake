if ( CMAKE_BINARY_DIR STREQUAL CMAKE_SOURCE_DIR )
  message(FATAL_ERROR "********* FATAL: Source and build directories cannot be the same. ********* Remove CMakeCache.txt from ${CMAKE_SOURCE_DIR}")
endif()

if (NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 11)
endif()

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

option(BUILD_SHARED_LIBS "Build the shared library" ON)
option(CODE_COVERAGE "Build with code coverage" OFF)
option(BUILD_TESTING "Build with tests and samples" OFF)
option(WITH_SAMPLES "Build with samples" ON)
option(PARANOID_WARNING "Paranoid warning level" OFF)

if (NOT CMAKE_BUILD_TYPE)
  message(STATUS "No build type selected, default to Release")
  set(CMAKE_BUILD_TYPE "Release")
endif()

if ( CODE_COVERAGE )
  set(BUILD_TESTING ON)
  set(WITH_SAMPLES OFF)
  set(CMAKE_BUILD_TYPE "Debug")
  set(CMAKE_CXX_FLAGS_DEBUG "-fprofile-arcs -ftest-coverage")
endif()

if ( ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang") 
      OR ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU") )
      
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -W -Wall -Werror -pedantic -ftemplate-depth=1024 -ftemplate-backtrace-limit=0")
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -DNDEBUG ")
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO  "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} -O2 -g -DNDEBUG")
  set(CMAKE_CXX_FLAGS_DEBUG  "${CMAKE_CXX_FLAGS_DEBUG} -O0 -g")
  
  if ( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" )
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D__STRICT_ANSI__ ${CLANG_LIBPP} ")   #-stdlib=libc++
  endif()

  if ( PARANOID_WARNING )
  
    if ( CMAKE_COMPILER_IS_GNUCXX )
    
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wlogical-op  -Wnoexcept -Wstrict-null-sentinel ")
      
      if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.9)
       set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wstack-protector")
      endif()
      
      if( (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 7) OR (CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 7) )
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wstringop-overflow=0")
      endif()
    endif()
    
    if ( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" )
    endif()
  
    # -Wlong-long ?? 
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wextra -ftemplate-depth=1400 -Wcast-align -Winvalid-pch -pedantic-errors  -Wformat-nonliteral")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wcomment -Wconversion -Wformat-security -Wimport  -Wchar-subscripts")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wcast-qual -Wctor-dtor-privacy -Wdisabled-optimization -Wformat-y2k")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}  -Wmissing-braces -Wmissing-field-initializers")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wmissing-format-attribute -Wpacked -Wparentheses -Wpointer-arith")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wreturn-type -Wsequence-point -Wsign-compare -Wuninitialized")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wstrict-aliasing -Wstrict-aliasing=2 -Wswitch-enum -Wtrigraphs -Wunknown-pragmas")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wfloat-equal  -Wformat -Wformat=2 -Winit-self  -Wmissing-declarations")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wunreachable-code -Wunused -Wunused-function -Wunused-label -Wunused-parameter -Wunused-value")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wunused-variable  -Wvariadic-macros -Wvolatile-register-var  -Wwrite-strings")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wmissing-include-dirs -Wold-style-cast -Woverloaded-virtual")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wredundant-decls -Wshadow -Wsign-conversion -Wsign-promo ")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}  -Wswitch -Wswitch-default -Wundef -Werror -Wunused-result")
    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
      # -Wnoexcept
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wlogical-op  -Wstrict-null-sentinel")
    endif()
  endif(PARANOID_WARNING)
elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
# using Intel C++
endif()

if ( CMAKE_CXX_STANDARD EQUAL 98 )
  option(DISABLE_LONG_LONG_98 "Disable long-long for 98" OFF)
  if ( DISABLE_LONG_LONG_98 )
    add_definitions( -DDISABLE_LONG_LONG_98=OFF )
  else()
    add_definitions( -DDISABLE_LONG_LONG_98=OFF )
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-long-long")
  endif()
  
endif()


set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}/archive")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}/bin/lib")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}/bin")
set(UNIT_TEST_BIN_OUTPUT_DIR "${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}/tests")


