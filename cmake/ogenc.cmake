#
# Author: Vladimir Migashko <migashko@gmail.com>, (C) 2021
#
# Copyright: See COPYING file that comes with this distribution
#
# https://github.com/migashko/ogenc
# 

macro(ogenc_env OPT_NAME TEXT VALUE )
  if (DEFINED ENV{${OPT_NAME}} AND NOT DEFINED ${OPT_NAME})
    set(${OPT_NAME} $ENV{${OPT_NAME}} CACHE STRING "${TEXT}" FORCE)
  else()
    option(${OPT_NAME} "${TEXT}" ${VALUE})
  endif()
endmacro()

ogenc_env(EXTRA_WARNINGS "Extra warnings level" ON)
ogenc_env(DISABLE_WARNINGS "Disable warnings (also ignore EXTRA_WARNINGS and PARANOID_WARNINGS)" OFF)
ogenc_env(PARANOID_WARNINGS "Paranoid warnings level" OFF)
ogenc_env(OGENC_WARNINGS "Paranoid warnings level" OFF)
ogenc_env(PARANOID_OPTIMIZE "Paranoid optimize level" OFF)
ogenc_env(OGENC_OPTIMIZE "Paranoid optimize level" OFF)
ogenc_env(APOCALYPTIC_WARNINGS "Paranoid warnings level include submodules" OFF)

if (APOCALYPTIC_WARNINGS)
  set(PARANOID_WARNINGS ON)
endif()

if ( PARANOID_WARNINGS OR OGENC_WARNINGS )
  set(PARANOID_WARNINGS ON)
  set(OGENC_WARNINGS ON)
endif()

if ( PARANOID_OPTIMIZE OR OGENC_OPTIMIZE )
  set(PARANOID_OPTIMIZE ON)
  set(OGENC_OPTIMIZE ON)
endif()

include(${CMAKE_CURRENT_LIST_DIR}/ogenc/ogenc-option.cmake)

if ( PARANOID_WARNINGS )
  include(${CMAKE_CURRENT_LIST_DIR}/ogenc/gen/warnings-g++.cmake)
  include(${CMAKE_CURRENT_LIST_DIR}/ogenc/gen/warnings-clang++.cmake)
endif()

if ( PARANOID_OPTIMIZE OR OGENC_OPTIMIZE )
  include(${CMAKE_CURRENT_LIST_DIR}/ogenc/gen/optimize-g++.cmake)
  include(${CMAKE_CURRENT_LIST_DIR}/ogenc/gen/optimize-clang++.cmake)
endif()

function(target_ogenc_warnings target)  
  if ( NOT DISABLE_WARNINGS )
    target_compile_options(${target} PRIVATE -Werror -Wall)
    if ( EXTRA_WARNINGS OR PARANOID_WARNINGS)
      target_compile_options(${target} PRIVATE -Wextra -Wpedantic -Wformat -pedantic-errors)
      if ( PARANOID_WARNINGS )
        if ( NOT ${target}_warning_options )
          target_compile_options(${target} PRIVATE ${ogenc_warning_options} )
        else()
          target_compile_options(${target} PRIVATE ${${target}_warning_options} )
        endif()
      endif()
    endif()
  endif()
endfunction()

function(target_ogenc_optimize target)
  if ( OGENC_OPTIMIZE )
    target_compile_options(${target} PRIVATE ${ogenc_optimize_options} )
  endif()
endfunction()
