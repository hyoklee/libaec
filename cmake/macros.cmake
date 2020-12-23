macro(check_clzll VARIABLE)
  check_c_source_compiles(
    "int main(int argc, char *argv[])
{return __builtin_clzll(1LL);}"
    ${VARIABLE}
    )
endmacro()

macro(check_bsr64 VARIABLE)
  check_c_source_compiles(
    "int main(int argc, char *argv[])
{unsigned long foo; unsigned __int64 bar=1LL;
return _BitScanReverse64(&foo, bar);}"
    ${VARIABLE}
    )
endmacro()

macro(find_inline_keyword)
  #Inspired from http://www.cmake.org/Wiki/CMakeTestInline
  set(INLINE_TEST_SRC "/* Inspired by autoconf's c.m4 */
static inline int static_foo(){return 0\;}
int main(int argc, char *argv[]){return 0\;}
")
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/CMakeTestCInline.c
    ${INLINE_TEST_SRC})

  foreach(KEYWORD "inline" "__inline__" "__inline")
    if(NOT DEFINED C_INLINE)
      try_compile(C_HAS_${KEYWORD}
        ${CMAKE_CURRENT_BINARY_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}/CMakeTestCInline.c
        COMPILE_DEFINITIONS "-Dinline=${KEYWORD}"
        )
      if(C_HAS_${KEYWORD})
        set(C_INLINE TRUE)
        add_definitions("-Dinline=${KEYWORD}")
        message(STATUS "Inline keyword found - ${KEYWORD}")
      endif(C_HAS_${KEYWORD})
    endif(NOT DEFINED C_INLINE)
  endforeach(KEYWORD)

  if(NOT DEFINED C_INLINE)
    add_definitions("-Dinline=")
    message(STATUS "Inline keyword - not found")
  endif(NOT DEFINED C_INLINE)
endmacro(find_inline_keyword)

macro(find_restrict_keyword)
  set(RESTRICT_TEST_SRC "/* Inspired by autoconf's c.m4 */
int foo (int * restrict ip){return ip[0]\;}
int main(int argc, char *argv[]){int s[1]\;
int * restrict t = s\; t[0] = 0\; return foo(t)\;}
")

  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/CMakeTestCRestrict.c
    ${RESTRICT_TEST_SRC})

  foreach(KEYWORD "restrict" "__restrict" "__restrict__" "_Restrict")
    if(NOT DEFINED C_RESTRICT)
      try_compile(C_HAS_${KEYWORD}
        ${CMAKE_CURRENT_BINARY_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}/CMakeTestCRestrict.c
        COMPILE_DEFINITIONS "-Drestrict=${KEYWORD}"
        )
      if(C_HAS_${KEYWORD})
        set(C_RESTRICT TRUE)
        add_definitions("-Drestrict=${KEYWORD}")
        message(STATUS "Restrict keyword found - ${KEYWORD}")
      endif(C_HAS_${KEYWORD})
    endif(NOT DEFINED C_RESTRICT)
  endforeach(KEYWORD)

  if(NOT DEFINED C_RESTRICT)
    add_definitions("-Drestrict=")
    message(STATUS "Restrict keyword - not found")
  endif(NOT DEFINED C_RESTRICT)
endmacro(find_restrict_keyword)

#-------------------------------------------------------------------------------
macro (SET_HDF_BUILD_TYPE)
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message (STATUS "Setting build type to 'RelWithDebInfo' as none was specified.")
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
      "MinSizeRel" "RelWithDebInfo")
  endif()
endmacro ()

macro (SET_NAMING)
  # Always use full RPATH, i.e. don't skip the full RPATH for the build tree
  set (CMAKE_SKIP_BUILD_RPATH  FALSE)
  # when building, don't use the install RPATH already
  # (but later on when installing)
  set (CMAKE_INSTALL_RPATH_USE_LINK_PATH  FALSE)
  # add the automatically determined parts of the RPATH
  # which point to directories outside the build tree to the install RPATH
  set (CMAKE_BUILD_WITH_INSTALL_RPATH ON)
  if (APPLE)
    set (CMAKE_INSTALL_NAME_DIR "@rpath")
    set (CMAKE_INSTALL_RPATH
        "@executable_path/../${${package_prefix}_INSTALL_LIB_DIR}"
        "@executable_path/"
        "@loader_path/../${${package_prefix}_INSTALL_LIB_DIR}"
        "@loader_path/"
    )
  else ()
    set (CMAKE_INSTALL_RPATH "\$ORIGIN/../${${package_prefix}_INSTALL_LIB_DIR}:\$ORIGIN/")
  endif ()

  if (DEFINED ADDITIONAL_CMAKE_PREFIX_PATH AND EXISTS "${ADDITIONAL_CMAKE_PREFIX_PATH}")
    set (CMAKE_PREFIX_PATH ${ADDITIONAL_CMAKE_PREFIX_PATH} ${CMAKE_PREFIX_PATH})
  endif ()

  #set the default debug suffix for all library targets
    if(NOT CMAKE_DEBUG_POSTFIX)
      if (WIN32)
        set (CMAKE_DEBUG_POSTFIX "_D")
      else ()
        set (CMAKE_DEBUG_POSTFIX "_debug")
      endif ()
  endif ()

  SET_HDF_BUILD_TYPE()
endmacro ()

macro (SET_BASE_OPTIONS libtarget libname libtype)
  # message (STATUS "${libname} libtype: ${libtype}")
  if (${libtype} MATCHES "SHARED")
    set (LIB_RELEASE_NAME "${libname}")
    set (LIB_DEBUG_NAME "${libname}${CMAKE_DEBUG_POSTFIX}")
  else ()
    if (WIN32 AND NOT MINGW)
      set (LIB_RELEASE_NAME "lib${libname}")
      set (LIB_DEBUG_NAME "lib${libname}${CMAKE_DEBUG_POSTFIX}")
    else ()
      set (LIB_RELEASE_NAME "${libname}")
      set (LIB_DEBUG_NAME "${libname}${CMAKE_DEBUG_POSTFIX}")
    endif ()
  endif ()

  set_target_properties (${libtarget}
      PROPERTIES
         OUTPUT_NAME                ${LIB_RELEASE_NAME}
#         OUTPUT_NAME_DEBUG          ${LIB_DEBUG_NAME}
         OUTPUT_NAME_RELEASE        ${LIB_RELEASE_NAME}
         OUTPUT_NAME_MINSIZEREL     ${LIB_RELEASE_NAME}
         OUTPUT_NAME_RELWITHDEBINFO ${LIB_RELEASE_NAME}
  )

  if (${libtype} MATCHES "STATIC")
    if (WIN32)
      set_target_properties (${libtarget}
          PROPERTIES
          COMPILE_PDB_NAME_DEBUG          ${LIB_DEBUG_NAME}
          COMPILE_PDB_NAME_RELEASE        ${LIB_RELEASE_NAME}
          COMPILE_PDB_NAME_MINSIZEREL     ${LIB_RELEASE_NAME}
          COMPILE_PDB_NAME_RELWITHDEBINFO ${LIB_RELEASE_NAME}
          COMPILE_PDB_OUTPUT_DIRECTORY    "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
      )
    endif ()
  endif ()

  #----- Use MSVC Naming conventions for Shared Libraries
  if (MINGW AND ${libtype} MATCHES "SHARED")
    set_target_properties (${libtarget}
        PROPERTIES
        IMPORT_SUFFIX ".lib"
        IMPORT_PREFIX ""
        PREFIX ""
    )
  endif ()
endmacro ()

