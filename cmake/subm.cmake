
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

# https://github.com/migashko/faslib.git > "https://github.com" "migashko" "faslib" "git"
# https://github.com/migashko/           > "https://github.com" "migashko" "" ""
# https://github.com/                    > "https://github.com" "" "" ""
# migashko/faslib.git                    > "" "migashko" "faslib" "git"
# migashko/faslib                        > "" "migashko" "faslib" ""
# migashko/faslib                        > "" "migashko" "faslib" ""
# faslib.git                             > "" "" "faslib" "git"
# faslib                                 > "" "" "faslib" ""
# ../faslib                              > "" ".." "faslib" ""
# ../../migahhko/faslib                  > "../.." "migashko" "faslib" ""

FUNCTION( wci_split_name )
  cmake_parse_arguments(arg "" "IN_STR;OUT_PREFIX;OUT_GROUP;OUT_NAME;OUT_EXT" "" ${ARGN} )

  set(CUR_STR "${arg_IN_STR}")
  string(REGEX MATCH "(\/|:)[^\/]*\/[^\/]*$" val "${CUR_STR}" )
  
  if ( NOT "${val}" STREQUAL "" )
    
    string(LENGTH ${val} val_len)
    string(LENGTH ${CUR_STR} in_len)
    MATH(EXPR pref_len "${in_len}-${val_len}+1")
    string(SUBSTRING ${CUR_STR} 0 ${pref_len} pref )
    set(${arg_OUT_PREFIX} "${pref}" PARENT_SCOPE)
    string(SUBSTRING ${val} 1 -1 res )
    set(CUR_STR "${res}")
  endif()
  
  string(REGEX MATCH ".*\/$" val "${CUR_STR}" )

  if ( NOT "${val}" STREQUAL "" )
    string(LENGTH ${val} val_len)
    MATH(EXPR gr_len "${val_len}-1")
    string(SUBSTRING ${val} 0 ${gr_len} out_gr)
    set(${arg_OUT_GROUP} ${out_gr} PARENT_SCOPE)
  else()
    get_filename_component(val "${CUR_STR}" DIRECTORY )
    set(${arg_OUT_GROUP} ${val} PARENT_SCOPE)

    get_filename_component(val "${CUR_STR}" NAME_WE )
    set(${arg_OUT_NAME} ${val} PARENT_SCOPE)

    get_filename_component(val "${CUR_STR}" EXT )
    set(${arg_OUT_EXT} ${val} PARENT_SCOPE)
  endif()
ENDFUNCTION ()

FUNCTION( wci_prepare_name )

  cmake_parse_arguments(arg "" "IN_STR;IN_REPO;OUT_NAME;OUT_URI" "" ${ARGN} )
  
  wci_split_name(IN_STR "${arg_IN_STR}" OUT_PREFIX in_pef OUT_GROUP in_gr OUT_NAME in_name OUT_EXT in_ex)
  set(${arg_OUT_NAME} "${in_name}" PARENT_SCOPE)

  set(out_ext "")
  if ( "${in_ex}" STREQUAL "")
    set(out_ext ".git")
  endif()

  # Если задано только имя, то смотрим нет ли для него определения имя_REPO 
  if ( ("${in_pref}" STREQUAL "") AND ( "${in_gr}" STREQUAL "") )
    if (DEFINED ${in_name}_REPO)
      set(${arg_OUT_URI} "${${in_name}_REPO}" PARENT_SCOPE)
      return()
    endif()
  endif()

  if ( (NOT "${in_pref}" STREQUAL "") OR ( "${in_gr}" STREQUAL "..") )
    # If full url https://github.com/migashko/faslib.git
    # Or relative ../../migashko/faslib.git or ../../migashko/faslib
    set(${arg_OUT_URI} "${arg_IN_STR}${out_ext}" PARENT_SCOPE)
    return()
  endif()
 
  if ( "${arg_IN_REPO}" STREQUAL ".")
    if ( "${in_gr}" STREQUAL "" )
      set(${arg_OUT_URI} "../${in_name}${out_ext}" PARENT_SCOPE)
    else()
      set(${arg_OUT_URI} "../../${in_gr}/${in_name}${out_ext}" PARENT_SCOPE)
    endif()
    return()
  endif()
  
  wci_split_name(IN_STR "${arg_IN_REPO}" OUT_PREFIX repo_pef OUT_GROUP repo_gr)

  if ( "${in_gr}" STREQUAL "" )
    set(${arg_OUT_URI} "${repo_pef}${repo_gr}/${in_name}${out_ext}" PARENT_SCOPE)
  else()
      set(${arg_OUT_URI} "${repo_pef}${in_gr}/${in_name}${out_ext}" PARENT_SCOPE)
  endif()
  
ENDFUNCTION ()



# Подключает git-субмодуль к проекту и инициализирует его, если еще не подключен
# Если подключен, то ничего не делает
# Параметры:
#   NAME - имя субмодуля
#   URL  - полный или относительный URL проекта
#   BRANCH - ветка проекта, на которую переключается при инициализации. Если собмодуль уже инициализирован, 
#    то переключения на эту ветку не происходит 
FUNCTION(wci_add_submodule)

  cmake_parse_arguments(arg "" "NAME;URL;BRANCH;OUT_STATUS" "" ${ARGN} )

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

  if ( NOT arg_BRANCH )
    set(arg_BRANCH master)
  endif()

  execute_process(
    COMMAND git submodule add -b "${arg_BRANCH}" "${arg_URL}" "${libdir}"
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    RESULT_VARIABLE EXIT_CODE
  )

  if ( EXIT_CODE EQUAL 0 ) 
    set( ${arg_OUT_STATUS} TRUE PARENT_SCOPE )
  else() 
    set( ${arg_OUT_STATUS} FALSE PARENT_SCOPE )
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
    set(arg_EXTERNAL TRUE)
  endif()

  if ( "${PROJECT_SOURCE_DIR}" STREQUAL "${WCI_DIR}" )
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

  wci_split_name(IN_STR ${arg_NAME} OUT_NAME name_lib)
  
  execute_process(
    COMMAND bash "-c" "ls -1 external/${name_lib} | wc -l"
    OUTPUT_VARIABLE EXIST_LIB_FILES
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    ERROR_QUIET
  )

  if( ${EXIST_LIB_FILES} EQUAL 0)
  
    message("Init submodule: external/${name_lib} ")

    execute_process(
      COMMAND git submodule update --init -- "external/${name_lib}"
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      RESULT_VARIABLE EXIT_CODE
      ERROR_QUIET
    )

    if ( NOT EXIT_CODE EQUAL 0 )

      set(status FALSE)
      foreach(REPO ${REPO_LIST})
        wci_prepare_name(IN_STR ${arg_NAME} IN_REPO ${REPO} OUT_NAME name_lib OUT_URI uri_lib)
        message(STATUS "Attempt to add submodule external/${name_lib} ${uri_lib}")
        wci_add_submodule(NAME "${name_lib}" URL "${uri_lib}" BRANCH "${arg_BRANCH}" OUT_STATUS status)
        if ( status )
          break()
        endif()
        set(status FALSE)
      endforeach()
      
      if ( status )
        message(STATUS "Successful add submodule external/${name_lib} ${uri_lib} BRANCH ${arg_BRANCH}")
      else()
        message(FATAL_ERROR "Unsuccessful add submodule external/${name_lib} ${uri_lib} BRANCH ${arg_BRANCH}")
      endif()
      
    endif()
  endif()
  wci_add_subdirectory(PATH "external/${name_lib}")
ENDFUNCTION(wci_submodule)
