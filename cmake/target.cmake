MACRO(wci_target_ target )
  target_compile_options(${target} PRIVATE ${common_wci_options})
  target_compile_definitions(${target} PRIVATE ${common_wci_definition})
  target_link_libraries(${target} PRIVATE ${common_wci_libraries})
  target_include_directories(${target} PRIVATE ${common_wci_includes})
  set_target_properties(${target} PROPERTIES ${common_wci_properties})
ENDMACRO(wci_target_)

MACRO(wci_util_ target )
  wci_target_(${target})
  set_target_properties(${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${UTIL_BIN_OUTPUT_DIR}")
ENDMACRO(wci_util_)

MACRO(wci_targets)
  foreach(arg IN ITEMS ${ARGN})
    wci_target_(${arg})
  endforeach()
ENDMACRO(wci_targets)

MACRO(wci_utils)
  foreach(arg IN ITEMS ${ARGN})
    wci_util_(${arg})
  endforeach()
ENDMACRO(wci_utils)

MACRO(wci_test)
  cmake_parse_arguments(args
    "NO_MEMCHECK"
    "NAME;TARGET;WORKING_DIRECTORY"
    "COMMAND;CONFIGURATIONS"
    ${ARGN}
  )

  if ( NOT args_NAME AND NOT args_TARGET)
    set(args_NAME "${ARGV0}")
    set(args_TARGET "${ARGV0}")
    if ( ARGV1 )
      set(args_COMMAND "${ARGV1}")
    else()
      set(args_COMMAND "${ARGV0}")
    endif()
  endif()

  if ( NOT args_COMMAND AND NOT args_TARGET )
    set(args_COMMAND "${args_NAME}")
    set(args_TARGET "${args_NAME}")
  endif()

  if ( NOT args_NAME )
    set(args_NAME "${args_TARGET}")
  endif()

  if ( NOT args_COMMAND )
    set(args_COMMAND "${args_TARGET}")
  endif()

  if ( NOT args_WORKING_DIRECTORY )
    set(args_WORKING_DIRECTORY "${UNIT_TEST_BIN_OUTPUT_DIR}")
  endif()

  if ( TARGET ${args_TARGET} )
    wci_target_(${args_TARGET})
    set_target_properties(${args_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${args_WORKING_DIRECTORY}")
  endif()

  add_test(NAME ${args_NAME} COMMAND ${args_COMMAND} CONFIGURATIONS ${args_CONFIGURATIONS} WORKING_DIRECTORY ${args_WORKING_DIRECTORY})

  if ( NOT CODE_COVERAGE AND NOT args_NO_MEMCHECK AND NOT NO_MEMCHECK)
    add_test(
      NAME "${args_NAME}-memcheck"
      COMMAND valgrind --tool=memcheck --leak-check=full --error-exitcode=1 ${args_WORKING_DIRECTORY}/${args_COMMAND} ${args_UNPARSED_ARGUMENTS}
      WORKING_DIRECTORY ${args_WORKING_DIRECTORY}
    )
  endif()
ENDMACRO(wci_test)

