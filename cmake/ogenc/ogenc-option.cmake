macro(ogenc_option target specific wname)

  unset(wopt)
  if (DEFINED ${wname})
    set( "${${wname}}")
  endif()

  if ( NOT DEFINED ${wopt} )
    if ( ${ARGC} GREATER 4 )
      set(wopt ${ARGV4})
    elseif( ${ARGC} GREATER  3 )
      set(wopt ${ARGV3})
    else()
      set(wopt ON)
    endif()
  endif()
  
  set(opt_list "${target}_${specific}_options")
  
  if ( NOT "${target}" STREQUAL "ogenc" )
    if (NOT ${opt_list})
      set(${opt_list} ${ogenc_${specific}_options})
    endif()
  endif()

  if ( ${wopt} )
    message(STATUS "OGENC ${specific} ${wname} for ${target}: ${wopt}" )
    list(APPEND opt_list wname )
  else()
    message(STATUS "OGENC ${specific} ${wname} for ${target}: ${wopt}" )
    list(REMOVE_ITEM opt_list wname )
  endif()
  list(SORT opt_list )
  list(REMOVE_DUPLICATES opt_list )
endmacro()

macro(ogenc_warning wname)
  ogenc_option(ogenc "warning" ${wname} ${ARGN} )
endmacro()

macro(ogenc_optimize wname)
  ogenc_option(ogenc "optimize" ${wname} ${ARGN} )
endmacro()

macro(update_ogenc)

  if ( NOT PARANOID_WARNINGS )
    return()
  endif()
  
  cmake_parse_arguments(args
    "ON;OFF;"
    ""
    "TARGETS;WARNINGS;OPTIMIZE;"
    ${ARGN}
  )
  
  set(value ON)
  
  if (args_ON AND args_OFF )
    message(FATAL_ERROR "Invalid combination is specified ON and OFF at the same time")
  endif()

  if (args_OFF)
    set(value OFF)
  endif()

  if (args_OPTIMIZE )
    set(specific "optimize")
  endif()
  
  foreach(target ${args_TARGETS})
    foreach(opt ${args_WARNINGS})
      ogenc_option( ${target} "warning" ${opt} ${value} )
    endforeach()
    foreach(opt ${args_OPTIMIZE})
      ogenc_option( ${target} "optimize" ${opt} ${value} )
    endforeach()
  endforeach()  
endmacro()

