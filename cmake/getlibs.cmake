FUNCTION( wci_submodule_subdirectory libdir)
    if (NOT APOCALYPTIC_MODE)
      set(PARANOID_WARNINGS OFF)
      set(OGENC_WARNINGS OFF)
    endif()
    set(BUILD_TESTING OFF)
    set(WITH_SAMPLES OFF)
    set(CODE_COVERAGE OFF)
    add_subdirectory("${PROJECT_SOURCE_DIR}/${libdir}")
ENDFUNCTION ()

# преобразует имя в части для полного url субмодуля в зависимости
# от установок глобальных переменных
FUNCTION( wci_prepare_name raw_name name_lib uri_lib)

  get_filename_component(namelib "${raw_name}" NAME_WE )

  if (DEFINED ${raw_name}_REPO)
    set(raw_name "${${raw_name}_REPO}")
  endif()

  get_filename_component(extlib "${raw_name}" EXT )

  if ( "${extlib}" STREQUAL "" )
    # Имя библиотеки с группой или без (cpp/wjson или wjson)
    set(preflib "${REPO_PREF}")
    set(extlib ".git")
    get_filename_component(dirlib "${raw_name}" DIRECTORY)
    if ( "${dirlib}" STREQUAL "" )
      set(grplib "${REPO_GROUP}")
    else()
      get_filename_component(grplib "${dirlib}" NAME_WE)
      set(grplib "${grplib}/")
    endif()
  else()
    # Указан полный путь ()
    get_filename_component(trash "${raw_name}" DIRECTORY)
    get_filename_component(grplib "${trash}" NAME)
    set(grplib "${grplib}/")

    string(LENGTH "${grplib}${namelib}${extlib}" tail_len)
    string(LENGTH "${raw_name}" lib_len)
    math(EXPR pref_len "${lib_len}-${tail_len}")
    string(SUBSTRING "${raw_name}" 0 ${pref_len} preflib)
  endif()

  set(${name_lib} "${namelib}" PARENT_SCOPE)
  set(${uri_lib} "${preflib}${grplib}${namelib}${extlib}" PARENT_SCOPE)
ENDFUNCTION ()


FUNCTION(wci_add_submodule namelib liburl branch)
  if ( NOT "${PROJECT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}" )
    message(FATAL_ERROR "Allowed to be used only in project directory: ${PROJECT_SOURCE_DIR}")
  endif()

  set(libdir "external/${namelib}")
  set(libpath "${PROJECT_SOURCE_DIR}/${libdir}")

  execute_process(
    COMMAND bash "-c" "ls -1 ${libdir} | wc -l"
    OUTPUT_VARIABLE EXIST_LIB_FILES
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    ERROR_QUIET
  )

  if( ${EXIST_LIB_FILES} EQUAL 0)

    message("Get ${liburl} library")

    execute_process(
      COMMAND
        git submodule update --init -- "${libdir}"
      WORKING_DIRECTORY
        ${PROJECT_SOURCE_DIR}
      RESULT_VARIABLE
        EXIT_CODE
      ERROR_QUIET
    )

    if ( NOT EXIT_CODE EQUAL 0 )
      if ( "${branch}" STREQUAL "" )
        set(branch master)
      endif()

      message("Clone ${namelib} library from ${liburl} branch ${branch}")
      execute_process(
        COMMAND
          git submodule add -b "${branch}" --force "${liburl}" "${libdir}"
        WORKING_DIRECTORY
          ${PROJECT_SOURCE_DIR}
        RESULT_VARIABLE
          EXIT_CODE
      )

      if ( NOT EXIT_CODE EQUAL 0 )
        message(FATAL_ERROR "WAMBA CMAKE-CI: Cannot add submodule ${liburl}")
      endif()

    elseif ( NOT "${branch}" STREQUAL ""  )

      message("Sumbodule ${libdir} checkout branch ${branch}")

      execute_process(
        COMMAND
          git checkout ${branch}
        WORKING_DIRECTORY
          ${libpath}
        RESULT_VARIABLE
          EXIT_CODE
        ERROR_QUIET
      )

      if ( NOT EXIT_CODE EQUAL 0 )
        message(FATAL_ERROR "WAMBA CMAKE-CI: Cannot checkout ${libdir} branch ${branch}")
      endif()

    endif()
  endif()
ENDFUNCTION(wci_add_submodule)


FUNCTION(wci_getlib )
  cmake_parse_arguments(arg "SUPERMODULE" "NAME;BRANCH" "" ${ARGN} )

  if ( NOT arg_NAME )
    set(arg_NAME "${ARGV0}")
    if ( NOT arg_BRANCH )
      set(arg_BRANCH "${ARGV1}")
    endif()
  endif()

  if ( NOT arg_BRANCH )
    set(arg_BRANCH "")
  endif()

  if ( arg_SUPERMODULE )
    set(WCI_SUPERMODULE "SUPERMODULE")
  else()
    if ( NOT WCI_SUPERMODULE)
      return()
    endif()
   unset(WCI_SUPERMODULE)
  endif()
  wci_prepare_name(${arg_NAME} name_lib uri_lib)
  wci_add_submodule("${name_lib}" "${uri_lib}" "${arg_BRANCH}")
  wci_submodule_subdirectory("external/${name_lib}")
ENDFUNCTION(wci_getlib)

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
          ${CMAKE_SOURCE_DIR}/external/cmake-ci/scripts/get_boost.sh 1.76.0 ${ARGV}
        WORKING_DIRECTORY
          ${CMAKE_BINARY_DIR}
        RESULT_VARIABLE
          EXIT_CODE
      )
      get_boost_(${ARGV})
    endif()
  endif()
endmacro(get_boost)
