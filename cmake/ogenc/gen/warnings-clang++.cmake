if ( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" )
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 3.4 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 3.4 )
    include(${CMAKE_CURRENT_LIST_DIR}/warnings-clang++-3.4.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 3.8 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 3.8 )
    include(${CMAKE_CURRENT_LIST_DIR}/warnings-clang++-3.8.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 4.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/warnings-clang++-4.0.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 7.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 7.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/warnings-clang++-7.0.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 8.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 8.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/warnings-clang++-8.0.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 11.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 11.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/warnings-clang++-11.0.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 12.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 12.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/warnings-clang++-12.0.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 13.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 13.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/warnings-clang++-13.0.cmake)
  endif()
endif()

