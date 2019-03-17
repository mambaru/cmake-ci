FUNCTION( add_sublibrary libdir)
    set(BUILD_TESTING OFF)
    set(PARANOID_WARNING OFF)
    set(CODE_COVERAGE OFF)
    set(WITH_SAMPLES OFF)
    set(CMAKE_CXX_FLAGS "")
    set(CMAKE_CXX_FLAGS_RELEASE "")
    set(CMAKE_CXX_FLAGS_RELWITHDEBINFO  "")
    set(CMAKE_CXX_FLAGS_DEBUG  "")
    include(opt)
    add_subdirectory("${libdir}")
ENDFUNCTION ()

FUNCTION( get_liburl curlib liburl)
  if (DEFINED "${curlib}_REPO")
    set(liburl "${${curlib}_REPO}" PARENT_SCOPE)
  else()
    set(liburl "${REPO_PREFIX}/${curlib}.git" PARENT_SCOPE)
  endif()
ENDFUNCTION ()

MACRO(clonelib curlib)
  message("Check ${curlib} library")
  set(libdir "external/${curlib}")
  set(libpath "${CMAKE_CURRENT_SOURCE_DIR}/${libdir}")
  if ( ${curlib} STREQUAL "faslib" )
    set(FAS_TESTING_CPP "${libpath}/fas/testing/testing.cpp")
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
      get_liburl(${curlib} liburl)
      message("Clone ${curlib} library from ${liburl}")
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
ENDMACRO(clonelib)

MACRO(getlibs)
  set(list_var "${ARGN}")
  message("getlibs: ${list_var}")
  foreach(curlib IN LISTS list_var)
    clonelib(${curlib})
    set(libdir "external/${curlib}")
    set(libpath "${CMAKE_CURRENT_SOURCE_DIR}/${libdir}")
    list(APPEND CMAKE_MODULE_PATH "${libpath}/cmake")
    include_directories("${libpath}")
    add_sublibrary("${libdir}")
  endforeach(curlib)
ENDMACRO(getlibs)

FUNCTION(third_party_libs libs)
  message("third_party_libs: ${libs}")
  foreach(curlib IN LISTS libs)
    clonelib(${curlib})
    set(libdir "external/${curlib}")
    set(libpath "${CMAKE_CURRENT_SOURCE_DIR}/${libdir}")
    include_directories("${libpath}")
    set(CMAKE_BUILD_TYPE Release)
    #set(CMAKE_CXX_FLAGS "-fpic -O3 -DNDEBUG")
    set(CMAKE_CXX_FLAGS "")
    message("add_subdirectory: ${libdir}")
    add_subdirectory("${libdir}")
  endforeach(curlib)
ENDFUNCTION()

MACRO(rootlibs)
  if ( STANDALONE )
    getlibs(${ARGN})
  endif()
ENDMACRO(rootlibs)

MACRO(wfcroot)
  getlibs(wfcroot)
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wfc/cmake)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/)  
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wfc_jsonrpc)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wfc_io)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wfc_core)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wfc)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/iow)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wrtstat)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wjrpc)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wflow)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wlog)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/wjson)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/wfcroot/external/faslib)
  getlibs(${ARGN})
ENDMACRO(wfcroot)

MACRO(wfc_libs)
  if ( STANDALONE )
    list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/external/wfc/cmake)
    getlibs(faslib wjson wlog wflow iow wjrpc wrtstat wfc ${ARGN})
    include(FindThreads)
    find_package(Boost COMPONENTS system program_options filesystem date_time regex REQUIRED)
    set(WFC_LIBRARIES wfc iow wrtstat wlog wflow wjrpc ${Boost_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})
  endif()
ENDMACRO(wfc_libs)
