FUNCTION( add_sublibrary libdir)
    set(BUILD_TESTING OFF)
    set(PARANOID_WARNING OFF)
    add_subdirectory("${libdir}")
ENDFUNCTION ()

FUNCTION( get_liburl curlib liburl)
  if (DEFINED "${curlib}_REPO")
    set(liburl "${${curlib}_REPO}" PARENT_SCOPE)
  else()
    set(liburl "${REPO_PREFIX}/${curlib}.git" PARENT_SCOPE)
  endif()
ENDFUNCTION ()

MACRO(getlibs)
  set(list_var "${ARGN}")
  message("getlibs: ${list_var}")
  foreach(curlib IN LISTS list_var)
    message("Check ${curlib} library")
    set(libdir "external/${curlib}")
    if ( ${curlib} STREQUAL "faslib" )
      set(FAS_TESTING_CPP "${CMAKE_CURRENT_SOURCE_DIR}/${libdir}/fas/testing/testing.cpp")
    endif()
    
    execute_process(
      COMMAND bash "-c" "ls -1 ${libdir} | wc -l" 
      OUTPUT_VARIABLE EXIST_LIB_FILES
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      ERROR_QUIET
    )
    
    if( ${EXIST_LIB_FILES} EQUAL 0)
        message("Get ${curlib} library")
        
        execute_process(
          COMMAND 
            git submodule update --init -- "${libdir}"
          WORKING_DIRECTORY 
            ${CMAKE_CURRENT_SOURCE_DIR}
          RESULT_VARIABLE
            EXIT_CODE
          ERROR_QUIET
        )
        
        if ( NOT EXIT_CODE EQUAL 0 )
          message("Clone ${curlib} library")
          get_liburl(${curlib} liburl)
          execute_process(
            COMMAND 
              git submodule add --force "${liburl}" "${libdir}"
            WORKING_DIRECTORY 
              ${CMAKE_CURRENT_SOURCE_DIR}
            RESULT_VARIABLE
              EXIT_CODE
          )
        endif()

        if ( NOT EXIT_CODE EQUAL 0 )
          message(FATAL_ERROR "WAMBA CMAKE-CI: Cannot add submodule git@github.lan:cpp/${curlib}.git")
        endif()
    endif()
    include_directories("${libdir}")
    add_sublibrary("${libdir}")
  endforeach(curlib)
ENDMACRO(getlibs)

MACRO(rootlibs)
  if ( STANDALONE )
    getlibs(${ARGN})
  endif()
ENDMACRO(rootlibs)

MACRO(wfcroot)
  getlibs(wfcroot)
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wfc/cmake)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wfc)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/iow)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wjson)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/faslib)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wlog)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wflow)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wrtstat)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wjrpc)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/)
ENDMACRO(wfcroot)

MACRO(wfc_libs)
  if ( STANDALONE )
    list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/external/wfc/cmake)
    getlibs(faslib wjson wlog wflow iow wjrpc wrtstat wfc)
    include(FindThreads)
    find_package(Boost COMPONENTS system program_options filesystem date_time regex REQUIRED)
    set(WFC_LIBRARIES wfc wrtstat wlog wflow wjrpc ${Boost_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})
  endif()
ENDMACRO(wfc_libs)

MACRO(wfc_packages)
  if ( STANDALONE )
    getlibs(${ARGN})
  endif()
ENDMACRO(wfc_packages)
