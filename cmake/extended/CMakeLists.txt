cmake_minimum_required(VERSION 3.1)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -Wformat -Werror")
include(advanced.cmake)
add_executable(test_cpp test.cpp)
