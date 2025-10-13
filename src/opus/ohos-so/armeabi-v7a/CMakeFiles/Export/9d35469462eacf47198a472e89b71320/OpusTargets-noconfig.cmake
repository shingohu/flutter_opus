#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "Opus::opus" for configuration ""
set_property(TARGET Opus::opus APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(Opus::opus PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libopus.so.0.10.1"
  IMPORTED_SONAME_NOCONFIG "libopus.so.0"
  )

list(APPEND _cmake_import_check_targets Opus::opus )
list(APPEND _cmake_import_check_files_for_Opus::opus "${_IMPORT_PREFIX}/lib/libopus.so.0.10.1" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
