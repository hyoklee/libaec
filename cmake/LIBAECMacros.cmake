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
  get_property(_isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
  if(_isMultiConfig)
    set(HDF_CFG_NAME ${CMAKE_BUILD_TYPE})
    set(HDF_BUILD_TYPE ${CMAKE_CFG_INTDIR})
    set(HDF_CFG_BUILD_TYPE \${CMAKE_INSTALL_CONFIG_NAME})
  else()
    set(HDF_CFG_BUILD_TYPE ".")
    if(CMAKE_BUILD_TYPE)
      set(HDF_CFG_NAME ${CMAKE_BUILD_TYPE})
      set(HDF_BUILD_TYPE ${CMAKE_BUILD_TYPE})
    else()
      set(HDF_CFG_NAME "Release")
      set(HDF_BUILD_TYPE "Release")
    endif()
  endif()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message (STATUS "Setting build type to 'RelWithDebInfo' as none was specified.")
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
      "MinSizeRel" "RelWithDebInfo")
  endif()
endmacro ()

#-------------------------------------------------------------------------------
macro (LIBAEC_SET_LIB_OPTIONS libtarget libname libtype)
  # message (STATUS "${libname} libtype: ${libtype}")
  set (LIB_OUT_NAME "${libname}")

  if (${libtype} MATCHES "SHARED")
    set (PACKAGE_SOVERSION ${LIBAEC_PACKAGE_SOVERSION})
    set (PACKAGE_COMPATIBILITY ${LIBAEC_VERS_MAJOR}.0.0)
    set (PACKAGE_CURRENT ${LIBAEC_VERS_MAJOR}.${LIBAEC_VERS_MINOR}.0)
    if (WIN32)
      set (LIB_VERSION ${LIBAEC_PACKAGE_VERSION_MAJOR})
    else ()
      set (LIB_VERSION ${LIBAEC_PACKAGE_SOVERSION_MAJOR})
    endif ()
    set_target_properties (${libtarget} PROPERTIES VERSION ${PACKAGE_SOVERSION})
    if (WIN32)
        set (${LIB_OUT_NAME} "${LIB_OUT_NAME}-${LIB_VERSION}")
    else ()
        set_target_properties (${libtarget} PROPERTIES SOVERSION ${LIB_VERSION})
    endif ()
    if (CMAKE_C_OSX_CURRENT_VERSION_FLAG)
      set_property(TARGET ${libtarget} APPEND PROPERTY
          LINK_FLAGS "${CMAKE_C_OSX_CURRENT_VERSION_FLAG}${PACKAGE_CURRENT} ${CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG}${PACKAGE_COMPATIBILITY}"
      )
    endif ()
  endif ()
  LIBAEC_SET_BASE_OPTIONS (${libtarget} ${LIB_OUT_NAME} ${libtype})

  #-- Apple Specific install_name for libraries
  if (APPLE)
    option (LIBAEC_BUILD_WITH_INSTALL_NAME "Build with library install_name set to the installation path" OFF)
    if (LIBAEC_BUILD_WITH_INSTALL_NAME)
      set_target_properties (${libtarget} PROPERTIES
          INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/lib"
          BUILD_WITH_INSTALL_RPATH ${LIBAEC_BUILD_WITH_INSTALL_NAME}
      )
    endif ()
    if (LIBAEC_BUILD_FRAMEWORKS)
      if (${libtype} MATCHES "SHARED")
        # adapt target to build frameworks instead of dylibs
        set_target_properties(${libtarget} PROPERTIES
            XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
            FRAMEWORK TRUE
            FRAMEWORK_VERSION ${LIBAEC_PACKAGE_VERSION_MAJOR}
            MACOSX_FRAMEWORK_IDENTIFIER org.hdfgroup.${libtarget}
            MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${LIBAEC_PACKAGE_VERSION_MAJOR}
            MACOSX_FRAMEWORK_BUNDLE_VERSION ${LIBAEC_PACKAGE_VERSION_MAJOR})
      endif ()
    endif ()
  endif ()
endmacro ()

#-------------------------------------------------------------------------------
macro (SET_GLOBAL_VARIABLE name value)
  set (${name} ${value} CACHE INTERNAL "Used to pass variables between directories" FORCE)
endmacro ()

#-------------------------------------------------------------------------------
macro (IDE_GENERATED_PROPERTIES SOURCE_PATH HEADERS SOURCES)
  #set(source_group_path "Source/AIM/${NAME}")
  string (REPLACE "/" "\\\\" source_group_path ${SOURCE_PATH})
  source_group (${source_group_path} FILES ${HEADERS} ${SOURCES})

  #-- The following is needed if we ever start to use OS X Frameworks but only
  #--  works on CMake 2.6 and greater
  #set_property (SOURCE ${HEADERS}
  #       PROPERTY MACOSX_PACKAGE_LOCATION Headers/${NAME}
  #)
endmacro ()

#-------------------------------------------------------------------------------
macro (IDE_SOURCE_PROPERTIES SOURCE_PATH HEADERS SOURCES)
  #  install (FILES ${HEADERS}
  #       DESTINATION include/R3D/${NAME}
  #       COMPONENT Headers
  #  )

  string (REPLACE "/" "\\\\" source_group_path ${SOURCE_PATH}  )
  source_group (${source_group_path} FILES ${HEADERS} ${SOURCES})

  #-- The following is needed if we ever start to use OS X Frameworks but only
  #--  works on CMake 2.6 and greater
  #set_property (SOURCE ${HEADERS}
  #       PROPERTY MACOSX_PACKAGE_LOCATION Headers/${NAME}
  #)
endmacro ()

#-------------------------------------------------------------------------------
macro (INSTALL_TARGET_PDB libtarget targetdestination targetcomponent)
  if (WIN32 AND MSVC AND NOT DISABLE_PDB_FILES)
    get_target_property (target_type ${libtarget} TYPE)
    if (${libtype} MATCHES "SHARED")
      set (targetfilename $<TARGET_PDB_FILE:${libtarget}>)
    else ()
      get_property (target_name TARGET ${libtarget} PROPERTY $<IF:$<CONFIG:Debug>,OUTPUT_NAME_DEBUG,OUTPUT_NAME_RELWITHDEBINFO>)
      set (targetfilename $<TARGET_FILE_DIR:${libtarget}>/${target_name}.pdb)
    endif ()
    install (
      FILES ${targetfilename}
      DESTINATION ${targetdestination}
      CONFIGURATIONS Debug RelWithDebInfo
      COMPONENT ${targetcomponent}
      OPTIONAL
    )
  endif ()
endmacro ()

#-------------------------------------------------------------------------------
macro (INSTALL_PROGRAM_PDB progtarget targetdestination targetcomponent)
  if (WIN32 AND MSVC)
    install (
      FILES $<TARGET_PDB_FILE:${progtarget}>
      DESTINATION ${targetdestination}
      CONFIGURATIONS Debug RelWithDebInfo
      COMPONENT ${targetcomponent}
      OPTIONAL
    )
  endif ()
endmacro ()

#-------------------------------------------------------------------------------
macro (LIBAEC_SET_BASE_OPTIONS libtarget libname libtype)
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

  set_target_properties (${libtarget} PROPERTIES
      OUTPUT_NAME                ${LIB_RELEASE_NAME}
#      OUTPUT_NAME_DEBUG          ${LIB_DEBUG_NAME}
      OUTPUT_NAME_RELEASE        ${LIB_RELEASE_NAME}
      OUTPUT_NAME_MINSIZEREL     ${LIB_RELEASE_NAME}
      OUTPUT_NAME_RELWITHDEBINFO ${LIB_RELEASE_NAME}
  )

  if (${libtype} MATCHES "STATIC")
    if (WIN32)
      set_target_properties (${libtarget} PROPERTIES
          COMPILE_PDB_NAME_DEBUG          ${LIB_DEBUG_NAME}
          COMPILE_PDB_NAME_RELEASE        ${LIB_RELEASE_NAME}
          COMPILE_PDB_NAME_MINSIZEREL     ${LIB_RELEASE_NAME}
          COMPILE_PDB_NAME_RELWITHDEBINFO ${LIB_RELEASE_NAME}
          COMPILE_PDB_OUTPUT_DIRECTORY    "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
      )
    endif ()
  endif ()

  option (HDF5_MSVC_NAMING_CONVENTION "Use MSVC Naming conventions for Shared Libraries" OFF)
  if (HDF5_MSVC_NAMING_CONVENTION AND MINGW AND ${libtype} MATCHES "SHARED")
    set_target_properties (${libtarget} PROPERTIES
        IMPORT_SUFFIX ".lib"
        IMPORT_PREFIX ""
        PREFIX ""
    )
  endif ()
endmacro ()

#-------------------------------------------------------------------------------
macro (LIBAEC_IMPORT_SET_LIB_OPTIONS libtarget libname libtype libversion)
  LIBAEC_SET_BASE_OPTIONS (${libtarget} ${libname} ${libtype})

  if (${importtype} MATCHES "IMPORT")
    set (importprefix "${CMAKE_STATIC_LIBRARY_PREFIX}")
  endif ()
  if (${HDF_CFG_NAME} MATCHES "Debug")
    set (IMPORT_LIB_NAME ${LIB_DEBUG_NAME})
  else ()
    set (IMPORT_LIB_NAME ${LIB_RELEASE_NAME})
  endif ()

  if (${libtype} MATCHES "SHARED")
    if (WIN32)
      if (MINGW)
        set_target_properties (${libtarget} PROPERTIES
            IMPORTED_IMPLIB "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${IMPORT_LIB_NAME}.lib"
            IMPORTED_LOCATION "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${IMPORT_LIB_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}"
        )
      else ()
        set_target_properties (${libtarget} PROPERTIES
            IMPORTED_IMPLIB "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${HDF_BUILD_TYPE}/${CMAKE_IMPORT_LIBRARY_PREFIX}${IMPORT_LIB_NAME}${CMAKE_IMPORT_LIBRARY_SUFFIX}"
            IMPORTED_LOCATION "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${HDF_BUILD_TYPE}/${CMAKE_IMPORT_LIBRARY_PREFIX}${IMPORT_LIB_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}"
        )
      endif ()
    else ()
      if (MINGW)
        set_target_properties (${libtarget} PROPERTIES
            IMPORTED_IMPLIB "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${IMPORT_LIB_NAME}.lib"
            IMPORTED_LOCATION "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${IMPORT_LIB_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}"
        )
      elseif (CYGWIN)
        set_target_properties (${libtarget} PROPERTIES
            IMPORTED_IMPLIB "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_IMPORT_LIBRARY_PREFIX}${IMPORT_LIB_NAME}${CMAKE_IMPORT_LIBRARY_SUFFIX}"
            IMPORTED_LOCATION "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_IMPORT_LIBRARY_PREFIX}${IMPORT_LIB_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}"
        )
      else ()
        set_target_properties (${libtarget} PROPERTIES
            IMPORTED_LOCATION "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_SHARED_LIBRARY_PREFIX}${IMPORT_LIB_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}"
            IMPORTED_SONAME "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_SHARED_LIBRARY_PREFIX}${IMPORT_LIB_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}.${libversion}"
            SOVERSION "${libversion}"
        )
      endif ()
    endif ()
  else ()
    if (WIN32 AND NOT MINGW)
      set_target_properties (${libtarget} PROPERTIES
          IMPORTED_LOCATION "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${HDF_BUILD_TYPE}/${IMPORT_LIB_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX}"
          IMPORTED_LINK_INTERFACE_LANGUAGES "C"
      )
    else ()
      set_target_properties (${libtarget} PROPERTIES
          IMPORTED_LOCATION "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${CMAKE_STATIC_LIBRARY_PREFIX}${IMPORT_LIB_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX}"
          IMPORTED_LINK_INTERFACE_LANGUAGES "C"
      )
    endif ()
  endif ()
endmacro ()

#-------------------------------------------------------------------------------
macro (TARGET_C_PROPERTIES wintarget libtype)
  target_compile_options(${wintarget} PRIVATE
      $<$<C_COMPILER_ID:MSVC>:${WIN_COMPILE_FLAGS}>
      $<$<CXX_COMPILER_ID:MSVC>:${WIN_COMPILE_FLAGS}>
  )
  if(MSVC)
    set_property(TARGET ${wintarget} APPEND PROPERTY LINK_FLAGS "${WIN_LINK_FLAGS}")
  endif()
endmacro ()

macro (HDF_DIR_PATHS package_prefix)
  if (APPLE)
    option (${package_prefix}_BUILD_FRAMEWORKS "TRUE to build as frameworks libraries, FALSE to build according to BUILD_SHARED_LIBS" FALSE)
  endif ()

  if (NOT ${package_prefix}_INSTALL_BIN_DIR)
    set (${package_prefix}_INSTALL_BIN_DIR bin)
  endif ()
  if (NOT ${package_prefix}_INSTALL_LIB_DIR)
    if (APPLE)
      set (${package_prefix}_INSTALL_FMWK_DIR ${CMAKE_INSTALL_FRAMEWORK_PREFIX})
    endif ()
    set (${package_prefix}_INSTALL_LIB_DIR lib)
  endif ()
  if (NOT ${package_prefix}_INSTALL_INCLUDE_DIR)
    set (${package_prefix}_INSTALL_INCLUDE_DIR include)
  endif ()
  if (NOT ${package_prefix}_INSTALL_DATA_DIR)
    if (NOT MSVC)
      if (APPLE)
        if (${package_prefix}_BUILD_FRAMEWORKS)
          set (${package_prefix}_INSTALL_EXTRA_DIR ../SharedSupport)
        else ()
          set (${package_prefix}_INSTALL_EXTRA_DIR share)
        endif ()
        set (${package_prefix}_INSTALL_FWRK_DIR ${CMAKE_INSTALL_FRAMEWORK_PREFIX})
      endif ()
      set (${package_prefix}_INSTALL_DATA_DIR share)
    else ()
      set (${package_prefix}_INSTALL_DATA_DIR ".")
    endif ()
  endif ()
  if (NOT ${package_prefix}_INSTALL_CMAKE_DIR)
    set (${package_prefix}_INSTALL_CMAKE_DIR share/cmake)
  endif ()

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

#-----------------------------------------------------------------------------
# Setup output Directories
#-----------------------------------------------------------------------------
  if (NOT ${package_prefix}_EXTERNALLY_CONFIGURED)
    set (CMAKE_RUNTIME_OUTPUT_DIRECTORY
        ${PROJECT_BINARY_DIR}/bin CACHE PATH "Single Directory for all Executables."
    )
    set (CMAKE_LIBRARY_OUTPUT_DIRECTORY
        ${PROJECT_BINARY_DIR}/bin CACHE PATH "Single Directory for all Libraries"
    )
    set (CMAKE_ARCHIVE_OUTPUT_DIRECTORY
        ${PROJECT_BINARY_DIR}/bin CACHE PATH "Single Directory for all static libraries."
    )
    set (CMAKE_Fortran_MODULE_DIRECTORY
        ${PROJECT_BINARY_DIR}/bin CACHE PATH "Single Directory for all fortran modules."
    )
    get_property(_isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
    if(_isMultiConfig)
      set (CMAKE_TEST_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${CMAKE_BUILD_TYPE})
      set (CMAKE_PDB_OUTPUT_DIRECTORY
          ${PROJECT_BINARY_DIR}/bin CACHE PATH "Single Directory for all pdb files."
      )
    else ()
      set (CMAKE_TEST_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
    endif ()
  else ()
    # if we are externally configured, but the project uses old cmake scripts
    # this may not be set and utilities like H5detect will fail
    if (NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY)
      set (CMAKE_RUNTIME_OUTPUT_DIRECTORY ${EXECUTABLE_OUTPUT_PATH})
    endif ()
  endif ()

  if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    if (CMAKE_HOST_UNIX)
      set (CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/HDF_Group/${HDF5_PACKAGE_NAME}/${HDF5_PACKAGE_VERSION}"
        CACHE PATH "Install path prefix, prepended onto install directories." FORCE)
    else ()
      GetDefaultWindowsPrefixBase(CMAKE_GENERIC_PROGRAM_FILES)
      set (CMAKE_INSTALL_PREFIX
        "${CMAKE_GENERIC_PROGRAM_FILES}/HDF_Group/${HDF5_PACKAGE_NAME}/${HDF5_PACKAGE_VERSION}"
        CACHE PATH "Install path prefix, prepended onto install directories." FORCE)
      set (CMAKE_GENERIC_PROGRAM_FILES)
    endif ()
  endif ()
endmacro ()
