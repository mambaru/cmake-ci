if ( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" )
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 4.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/optimize-clang++-4.0.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 7.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 7.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/optimize-clang++-7.0.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 11.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 11.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/optimize-clang++-11.0.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 12.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 12.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/optimize-clang++-12.0.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 13.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 13.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/optimize-clang++-13.0.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 14.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 14.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/optimize-clang++-14.0.cmake)
  endif()
  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 17.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 17.0 )
    include(${CMAKE_CURRENT_LIST_DIR}/optimize-clang++-17.0.cmake)
  endif()
endif()

