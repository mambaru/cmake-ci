include(getlibs)

FUNCTION(get_rocksdb)
  SET(WITH_TESTS  OFF CACHE BOOL "Build with tests")
  set(WITH_TOOLS  OFF CACHE BOOL "Build with tools")
  set(WITH_GFLAGS OFF CACHE BOOL "Build with GFlags")
  set(WITH_SNAPPY ON  CACHE BOOL "Build with SNAPPY")
  set(WITH_LZ4    ON  CACHE BOOL "Build with lz4")
  set(WITH_ZLIB   ON  CACHE BOOL "Build with zlib")
  set(WITH_BZ2    ON  CACHE BOOL "Build with bz2")
  set(WITH_ZSTD   ON  CACHE BOOL "Build with zstd")
  third_party_libs(rocksdb)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/rocksdb)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/rocksdb/include)
ENDFUNCTION ()
