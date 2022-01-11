
# Вызывает add_subdirectory с предварительным отключением опций предупреждений, сборок тестов и примеров.
# Используется для подключения директорий git-модулей исходя из предположения, что модуль уже прошел 
# все необходимые процедуры и, в рамках текущего проекта, в дополнительных проверках и тестах нет необходимости.
# Это нужно для сокращения времени компиляции. Разработчику не требуется еще раз собирать и запускать тесты для
# этого модуля, если он ему доверяет. А также разбираться с экзотическими предупреждениями, если модуль не был
# протестирован с текущей версией компилятора.
#
# Параметры:
# PATH <<путь>> - Отоносительный или абсолютный путь к подкаталогу
# WARNINGS - не отключать предупреждения
# TESTING - не отключать сборку тестов
# SAMPLES - не отключать сборку примеров
# COVERAGE - не отключать компиляцию с покрытием тестов
# 
# Голобальные переменные
# APOCALYPTIC_WARNINGS - не отключать предупреждения
# APOCALYPTIC_BUILD - не отключать сборку тестов, примеров и отчетов о покрытии тестами
FUNCTION(wci_add_subdirectory)

  cmake_parse_arguments(arg "WARNINGS;TESTING;SAMPLES;COVERAGE" "PATH" "" ${ARGN} )

  if ( NOT arg_PATH )
    message(FATAL_ERROR "PATH argument is required") 
  endif()
  
  if ( NOT APOCALYPTIC_WARNINGS AND NOT WARNINGS)
    set(PARANOID_WARNINGS OFF)
    set(OGENC_WARNINGS OFF)
  endif()

  if (NOT APOCALYPTIC_BUILD AND NOT TESTING)
    set(BUILD_TESTING OFF)
  endif()
    
  if (NOT APOCALYPTIC_BUILD AND NOT SAMPLES)
    set(WITH_SAMPLES OFF)
  endif()
  
  if (NOT APOCALYPTIC_BUILD AND NOT COVERAGE)
    set(CODE_COVERAGE OFF)
  endif()      
  
  add_subdirectory("${PROJECT_SOURCE_DIR}/${arg_PATH}")
  
ENDFUNCTION ()


# преобразует имя в части для полного url субмодуля в зависимости
# от установок глобальных переменных
# IN_STR
# OUT_NAME
# OUT_URI
FUNCTION( wci_prepare_name )

  cmake_parse_arguments(arg "" "IN_STR;OUT_NAME;OUT_URI" "" ${ARGN} )

# wci_prepare_name raw_name name_lib uri_lib
  get_filename_component(namelib "${arg_IN_STR}" NAME_WE )

  if (DEFINED ${arg_IN_STR}_REPO)
    set(raw_name "${${arg_IN_STR}_REPO}")
  else()
    set(raw_name ${arg_IN_STR})
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

  set(${arg_OUT_NAME} "${namelib}" PARENT_SCOPE)
  set(${arg_OUT_URI} "${preflib}${grplib}${namelib}${extlib}" PARENT_SCOPE)
ENDFUNCTION ()

#FUNCTION(wci_add_submodule namelib liburl branch)
# Подключает git-субмодуль к проекту и инициализирует его, если еще не подключен
# Если подключен, то ничего не делает
# Параметры:
#   NAME - имя субмодуля
#   URL  - полный или относительный URL проекта
#   BRANCH - ветка проекта, на которую переключается при инициализации. Если собмодуль уже инициализирован, 
#    то переключения на эту ветку не происходит 
FUNCTION(wci_add_submodule)

  cmake_parse_arguments(arg "" "NAME;URL;BRANCH" "" ${ARGN} )

  if ( NOT arg_NAME )
    message(FATAL_ERROR "NAME argument is required") 
  endif()

  if ( NOT arg_URL )
    message(FATAL_ERROR "URL argument is required") 
  endif()

  if ( NOT "${PROJECT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}" )
    message(FATAL_ERROR "Allowed to be used only in project directory: ${PROJECT_SOURCE_DIR}")
  endif()

  set(libdir "external/${arg_NAME}")
  set(libpath "${PROJECT_SOURCE_DIR}/${libdir}")

  execute_process(
    COMMAND bash "-c" "ls -1 ${libdir} | wc -l"
    OUTPUT_VARIABLE EXIST_LIB_FILES
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    ERROR_QUIET
  )

  if( ${EXIST_LIB_FILES} EQUAL 0)

    message("Get ${arg_URL} library")

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
      if ( NOT arg_BRANCH )
        set(arg_BRANCH master)
      endif()

      message("Clone ${arg_NAME} library from ${arg_URL} branch ${arg_BRANCH}")

      execute_process(
        COMMAND
          git submodule add -b "${arg_BRANCH}" --force "${arg_URL}" "${libdir}"
        WORKING_DIRECTORY
          ${PROJECT_SOURCE_DIR}
        RESULT_VARIABLE
          EXIT_CODE
      )

      if ( NOT EXIT_CODE EQUAL 0 )
        message(FATAL_ERROR "WAMBA CMAKE-CI: Cannot add submodule ${arg_URL}")
      endif()

    elseif ( NOT "${arg_BRANCH}" STREQUAL ""  )

      message("Sumbodule ${libdir} checkout branch ${arg_BRANCH}")

      execute_process(
        COMMAND
          git checkout ${arg_BRANCH}
        WORKING_DIRECTORY
          ${libpath}
        RESULT_VARIABLE
          EXIT_CODE
        ERROR_QUIET
      )

      if ( NOT EXIT_CODE EQUAL 0 )
        message(FATAL_ERROR "WAMBA CMAKE-CI: Cannot checkout ${libdir} branch ${arg_BRANCH}")
      endif()

    endif()
  endif()
ENDFUNCTION(wci_add_submodule)

FUNCTION(wci_submodule_check_arguments name branch supermodule external internal private)

  if ( "${name}" STREQUAL "" )
    message(FATAL_ERROR "wci_submodule NAME '${name}' argument is required")
  endif()
  
  if ( ${supermodule} )
    if ( ${external} AND ( ${internal} OR ${private}) )
      message(FATAL_ERROR "wci_submodule NAME '${name}' SUPERMODULE EXTERNAL: invalid combination ")
    elseif ( ${internal} AND ( ${external} OR ${private}))
      message(FATAL_ERROR "wci_submodule NAME '${name}' SUPERMODULE INTERNAL: invalid combination ")
    elseif ( ${private} AND ( ${external} OR ${internal}))
      message(FATAL_ERROR "wci_submodule NAME '${name}' SUPERMODULE PRIVATE: invalid combination ")
    endif()
  endif()  

  ENDFUNCTION(wci_submodule_check_arguments)

FUNCTION(wci_submodule)

  cmake_parse_arguments(arg "SUPERMODULE;EXTERNAL;INTERNAL;PRIVATE" "NAME;BRANCH" "" ${ARGN} )

  wci_submodule_check_arguments("${arg_NAME}" "${arg_BRANCH}" 
                                "${arg_SUPERMODULE}" "${arg_EXTERNAL}" 
                                "${arg_INTERNAL}" "${arg_PRIVATE}")

  if ( arg_SUPERMODULE AND NOT arg_INTERNAL AND NOT arg_PRIVATE )
    message(STATUS "??? ${arg_SUPERMODULE} ?? ${arg_INTERNAL} ?? ${arg_PRIVATE} ???")
    set(arg_EXTERNAL TRUE)
  endif()
  
  
  if ( "${PROJECT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}" )

    unset(WCI_SUPERMODULE)
    # Это корневой проект AND NOT arg_EXTERNAL  
    if ( arg_SUPERMODULE )
      set(WCI_SUPERMODULE TRUE)
    endif()
  else()
    # Текущий проект - это супермодуль
    if ( WCI_SUPERMODULE )
      unset( WCI_SUPERMODULE )
      if ( arg_SUPERMODULE )
        if ( arg_INTERNAL )
          set(WCI_SUPERMODULE TRUE )
        elseif ( arg_PRIVATE)
          set(WCI_SUPERMODULE TRUE )
        else()
          # its arg_EXTERNAL 
        endif()        
      endif( arg_SUPERMODULE )
    else()
      return() # В простом субмодуле субмодули не подключаем
    endif()
  endif()

  wci_prepare_name(IN_STR ${arg_NAME} OUT_NAME name_lib OUT_URI uri_lib)
  wci_add_submodule(NAME "${name_lib}" URL "${uri_lib}" BRANCH "${arg_BRANCH}")
  wci_add_subdirectory(PATH "external/${name_lib}")

ENDFUNCTION(wci_submodule)



###############################################
FUNCTION(wci_getlib )

  #message(WARNING "wci_getlib is deprecated. Use wfc_submodule")
  
  cmake_parse_arguments(arg "SUPERMODULE;SUPERMODULE_IF_ROOT" "NAME;BRANCH" "" ${ARGN} )

  if ( NOT arg_NAME )
    if ( NOT "${ARGV0}" STREQUAL "SUPERMODULE")
      set(arg_NAME "${ARGV0}")
      if ( NOT arg_BRANCH )
        set(arg_BRANCH "${ARGV1}")
      endif()
    else()
      set(arg_SUPERMODULE SUPERMODULE)
    endif()
  endif()

  if ( NOT arg_BRANCH )
    set(arg_BRANCH "")
  endif()
  
  if ( arg_SUPERMODULE_IF_ROOT )
    if ( CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR )
      set (arg_SUPERMODULE SUPERMODULE)
    endif()
  endif()
    

  if ( arg_SUPERMODULE )
    set(WCI_SUPERMODULE SUPERMODULE)
  else()
    if ( NOT WCI_SUPERMODULE)
      return()
    endif()
    unset(WCI_SUPERMODULE)
  endif()
  
  wci_prepare_name(IN_STR ${arg_NAME} OUT_NAME name_lib OUT_URI uri_lib)
  wci_add_submodule(NAME "${name_lib}" URL "${uri_lib}" BRANCH "${arg_BRANCH}")
  wci_add_subdirectory(PATH "external/${name_lib}")
ENDFUNCTION(wci_getlib)


