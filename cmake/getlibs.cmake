
macro(get_boost_)
  set( Boost_INCLUDE_DIR "${CMAKE_BINARY_DIR}/boost/include" )
  set( Boost_LIBRARY_DIR "${CMAKE_BINARY_DIR}/boost/lib" )
  set( BOOST_ROOT "${CMAKE_BINARY_DIR}/boost/")
  
  unset(Boost_LIBRARIES)

  foreach(compo ${ARGV})
    if ( Boost_USE_STATIC_LIBS )
      find_library( ${compo}_LIB NAMES libboost_${compo}.a PATHS ${Boost_LIBRARY_DIR} NO_DEFAULT_PATH)
    else()
      find_library( ${compo}_LIB NAMES libboost_${compo}.so PATHS ${Boost_LIBRARY_DIR} NO_DEFAULT_PATH)
    endif()
    if ( "${${compo}_LIB}" STREQUAL "${compo}_LIB-NOTFOUND" )
      set(Boost_FOUND FALSE)
      message(STATUS "Not Found ${compo} ${${compo}_LIB}")
      break()
    endif()
    message(STATUS "Found ${compo} ${${compo}_LIB}")
    list(APPEND Boost_LIBRARIES ${${compo}_LIB} )
    if(NOT TARGET Boost::${compo})
      message(STATUS "\t Set Boost::${compo} ${Boost_INCLUDE_DIR} ${Boost_LIBRARY_DIR}")
      add_library(Boost::${compo} IMPORTED INTERFACE)
      set_property(TARGET Boost::${compo} PROPERTY
          INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${Boost_INCLUDE_DIR}>)
      set_property(TARGET Boost::${compo} PROPERTY
          INTERFACE_LINK_LIBRARIES ${${compo}_LIB})
    endif()
    set(Boost_FOUND TRUE)
  endforeach()

endmacro()

macro(get_boost)
  find_package(Boost 1.76.0 COMPONENTS ${ARGV} )
  if ( NOT Boost_FOUND )
    get_boost_(${ARGV})
    if ( NOT Boost_FOUND )
      execute_process(
        COMMAND
          ${WCI_DIR}/external/cmake-ci/scripts/get_boost.sh 1.76.0 ${ARGV}
        WORKING_DIRECTORY
          ${CMAKE_BINARY_DIR}
        RESULT_VARIABLE
          EXIT_CODE
      )
      if ( ${EXIT_CODE} EQUAL 0 )
        get_boost_(${ARGV})
      else()
        message(WARNING "Script get_boost.sh fail. error: ${EXIT_CODE}")
      endif()
    endif()
  endif()
endmacro(get_boost)
