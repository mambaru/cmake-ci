MACRO(wci_target_ target )
  target_ogenc_warnings(${target})
  target_ogenc_optimize(${target})
  target_compile_options(${target} PRIVATE ${${PROJECT_NAME}_wci_options})
  target_compile_definitions(${target} PRIVATE ${${PROJECT_NAME}_wci_definition})
  target_link_libraries(${target} PRIVATE ${${PROJECT_NAME}_wci_libraries})
  target_include_directories(${target} PRIVATE ${${PROJECT_NAME}_wci_includes})
  if ( ${PROJECT_NAME}_wci_properties )
    set_target_properties(${target} PROPERTIES ${${PROJECT_NAME}_wci_properties})
  endif()
ENDMACRO(wci_target_)

MACRO(wci_util_ target )
  wci_target_(${target})
  set_target_properties(${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${UTIL_BIN_OUTPUT_DIR}")
ENDMACRO(wci_util_)

MACRO(wci_example_ target )
  wci_target_(${target})
  set_target_properties(${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${EXAMPLES_BIN_OUTPUT_DIR}")
ENDMACRO(wci_example_)

MACRO(wci_benchmark_ target )
  wci_target_(${target})
  set_target_properties(${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${BENCHMARKS_BIN_OUTPUT_DIR}")
ENDMACRO(wci_benchmark_)

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

MACRO(wci_examples)
  foreach(arg IN ITEMS ${ARGN})
    wci_example_(${arg})
  endforeach()
ENDMACRO(wci_examples)

MACRO(wci_benchmarks)
  foreach(arg IN ITEMS ${ARGN})
    wci_benchmark_(${arg})
  endforeach()
ENDMACRO(wci_benchmarks)

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
    set_target_properties(${args_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${UNIT_TEST_BIN_OUTPUT_DIR}")
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

