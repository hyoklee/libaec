cmake_minimum_required(VERSION 3.1)
project (LIBAEC C)
#-----------------------------------------------------------------------------
# Basic LIBAEC stuff here
#-----------------------------------------------------------------------------
set(CMAKE_C_STANDARD 99)

#-----------------------------------------------------------------------------
# Define some CMake variables for use later in the project
#-----------------------------------------------------------------------------
set (LIBAEC_RESOURCES_DIR          ${LIBAEC_SOURCE_DIR}/cmake)
set (LIBAEC_SRC_DIR                ${LIBAEC_SOURCE_DIR}/src)
set (LIBAEC_TEST_SOURCE_DIR        ${LIBAEC_SOURCE_DIR}/tests)
set (LIBAEC_EXAMPLES_SOURCE_DIR    ${LIBAEC_SOURCE_DIR}/examples)

#-----------------------------------------------------------------------------
# Set the core names of all the libraries
#-----------------------------------------------------------------------------
set (LIBAEC_LIB_CORENAME            "aec")
set (SZIP_LIB_CORENAME              "sz")

#-----------------------------------------------------------------------------
# Set the true names of all the libraries if customized by external project
#-----------------------------------------------------------------------------
set (LIBAEC_LIB_NAME            "${LIBAEC_EXTERNAL_LIB_PREFIX}${LIBAEC_LIB_CORENAME}")
set (SZIP_LIB_NAME              "${LIBAEC_EXTERNAL_LIB_PREFIX}${SZIP_LIB_CORENAME}")

#-----------------------------------------------------------------------------
# Set the target names of all the libraries
#-----------------------------------------------------------------------------
set (LIBAEC_LIB_TARGET            "${LIBAEC_LIB_CORENAME}-static")
set (LIBAEC_LIBSH_TARGET          "${LIBAEC_LIB_CORENAME}-shared")
set (SZIP_LIB_TARGET              "${SZIP_LIB_CORENAME}-static")
set (SZIP_LIBSH_TARGET            "${SZIP_LIB_CORENAME}-shared")

set (libaec_VERS_MAJOR 1)
set (libaec_VERS_MINOR 0)
set (libaec_VERS_RELEASE 4)

#-----------------------------------------------------------------------------
set (LIBAEC_PACKAGE "libaec")
set (LIBAEC_PACKAGE_NAME "LIBAEC")
set (LIBAEC_PACKAGE_VERSION "${libaec_VERS_MAJOR}.${libaec_VERS_MINOR}")
set (LIBAEC_PACKAGE_VERSION_MAJOR "${libaec_VERS_MAJOR}.${libaec_VERS_MINOR}")
set (LIBAEC_PACKAGE_VERSION_MINOR "${libaec_VERS_RELEASE}")
set (LIBAEC_PACKAGE_STRING "${LIBAEC_PACKAGE_NAME} ${LIBAEC_PACKAGE_VERSION}")
set (LIBAEC_PACKAGE_TARNAME "${LIBAEC_PACKAGE_NAME}${LIBAEC_PACKAGE_EXT}")
set (LIBAEC_PACKAGE_URL "http://www.hdfgroup.org")
set (LIBAEC_PACKAGE_BUGREPORT "help@hdfgroup.org")
set (LIBAEC_PACKAGE_SOVERSION "${libaec_VERS_MAJOR}.${libaec_VERS_MINOR}.${libaec_VERS_RELEASE}")
set (LIBAEC_PACKAGE_SOVERSION_MAJOR "${libaec_VERS_MAJOR}")

#-----------------------------------------------------------------------------
# Include some macros for reusable code
#-----------------------------------------------------------------------------
include (${LIBAEC_RESOURCES_DIR}/LIBAECMacros.cmake)

HDF_DIR_PATHS(${LIBAEC_PACKAGE_NAME})

#-----------------------------------------------------------------------------
# Targets built within this project are exported at Install time for use
# by other projects
#-----------------------------------------------------------------------------
if (NOT LIBAEC_EXPORTED_TARGETS)
  set (LIBAEC_EXPORTED_TARGETS "libaec-targets")
endif ()

#-----------------------------------------------------------------------------
# To include a library in the list exported by the project AT BUILD TIME,
# add it to this variable. This is NOT used by Make Install, but for projects
# which include SZIP as a sub-project within their build tree
#-----------------------------------------------------------------------------
set_global_variable (LIBAEC_LIBRARIES_TO_EXPORT "")

#-----------------------------------------------------------------------------
# Run all the CMake configuration tests for our build environment
#-----------------------------------------------------------------------------
include (${LIBAEC_RESOURCES_DIR}/ConfigureChecks.cmake)

#-----------------------------------------------------------------------------
# Mac OS X Options
#-----------------------------------------------------------------------------
if (LIBAEC_BUILD_FRAMEWORKS AND NOT BUILD_SHARED_LIBS)
  set (BUILD_SHARED_LIBS ON CACHE BOOL "Build Shared Libraries")
endif ()

#-----------------------------------------------------------------------------
# Option to Build Shared and Static libs, default is shared
#-----------------------------------------------------------------------------
option (BUILD_SHARED_LIBS "Build Shared Libraries" ON)
set (CMAKE_POSITION_INDEPENDENT_CODE ON)

#-----------------------------------------------------------------------------
# When building utility executables that generate other (source) files :
# we make use of the following variables defined in the root CMakeLists.
# Certain systems may add /Debug or /Release to output paths
# and we need to call the executable from inside the CMake configuration
#-----------------------------------------------------------------------------
set (EXE_EXT "")
if (WIN32)
  set (EXE_EXT ".exe")
  add_definitions (-D_BIND_TO_CURRENT_VCLIBS_VERSION=1)
  add_definitions (-D_CRT_SECURE_NO_WARNINGS)
  add_definitions (-D_CONSOLE)
endif ()

if (MSVC)
  set (CMAKE_MFC_FLAG 0)
endif ()

set (MAKE_SYSTEM)
if (CMAKE_BUILD_TOOL MATCHES "make")
  set (MAKE_SYSTEM 1)
endif ()

set (CFG_INIT "/${CMAKE_CFG_INTDIR}")
if (MAKE_SYSTEM)
  set (CFG_INIT "")
endif ()

#-----------------------------------------------------------------------------
# Compiler specific flags : Shouldn't there be compiler tests for these
#-----------------------------------------------------------------------------
if (CMAKE_COMPILER_IS_GNUCC)
  set (CMAKE_C_FLAGS "${CMAKE_ANSI_CFLAGS} ${CMAKE_C_FLAGS} -std=c99 -fomit-frame-pointer -finline-functions -fno-common")
endif ()
if (CMAKE_COMPILER_IS_GNUCXX AND CMAKE_CXX_COMPILER_LOADED)
  set (CMAKE_CXX_FLAGS "${CMAKE_ANSI_CFLAGS} ${CMAKE_CXX_FLAGS} -fomit-frame-pointer -finline-functions -fno-common")
endif ()

#-----------------------------------------------------------------------------
# This is in here to help some of the GCC based IDES like Eclipse
# and code blocks parse the compiler errors and warnings better.
#-----------------------------------------------------------------------------
if (CMAKE_COMPILER_IS_GNUCC)
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fmessage-length=0")
endif ()
if (CMAKE_COMPILER_IS_GNUCXX AND CMAKE_CXX_COMPILER_LOADED)
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fmessage-length=0")
endif ()

#-----------------------------------------------------------------------------
# Include user macros
#-----------------------------------------------------------------------------
include (UserMacros.cmake)

#-----------------------------------------------------------------------------
# All libs/tests/examples need the main include directories
#-----------------------------------------------------------------------------
INCLUDE_DIRECTORIES (${LIBAEC_BINARY_DIR} ${LIBAEC_SOURCE_DIR}/src ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})

add_subdirectory (src)

#-----------------------------------------------------------------------------
# Dashboard and Testing Settings
#-----------------------------------------------------------------------------
option (BUILD_TESTING "Build LIBAEC Unit Testing" OFF)
if (BUILD_TESTING)
  set (DART_TESTING_TIMEOUT 1200 CACHE STRING
       "Timeout in seconds for each test (default 1200=20minutes)")
  enable_testing ()
  include (CTest)
  add_subdirectory (tests)
endif ()

#-----------------------------------------------------------------------------
# Generate the aec_config.h file containing user settings needed by compilation
#-----------------------------------------------------------------------------
configure_file (${LIBAEC_RESOURCES_DIR}/config.h.in ${CMAKE_CURRENT_BINARY_DIR}/aec_config.h)

include (CMakePackageConfigHelpers)

#-----------------------------------------------------------------------------
# Check for Installation Utilities
#-----------------------------------------------------------------------------
if (WIN32)
  set (PF_ENV_EXT "(x86)")
  find_program (NSIS_EXECUTABLE NSIS.exe PATHS "$ENV{ProgramFiles}\\NSIS" "$ENV{ProgramFiles${PF_ENV_EXT}}\\NSIS")
  if(NOT CPACK_WIX_ROOT)
    file(TO_CMAKE_PATH "$ENV{WIX}" CPACK_WIX_ROOT)
  endif ()
  find_program (WIX_EXECUTABLE candle  PATHS "${CPACK_WIX_ROOT}/bin")
endif ()

#-----------------------------------------------------------------------------
# Add file(s) to CMake Install
#-----------------------------------------------------------------------------
if (NOT LIBAEC_INSTALL_NO_DEVELOPMENT)
  install (
      FILES ${PROJECT_BINARY_DIR}/aec_config.h
      DESTINATION ${LIBAEC_INSTALL_INCLUDE_DIR}
      COMPONENT headers
  )
endif ()

#-----------------------------------------------------------------------------
# Add Target(s) to CMake Install for import into other projects
#-----------------------------------------------------------------------------
if (NOT LIBAEC_EXTERNALLY_CONFIGURED)
  install (
      EXPORT ${LIBAEC_EXPORTED_TARGETS}
      DESTINATION ${LIBAEC_INSTALL_CMAKE_DIR}/libaec
      FILE ${LIBAEC_PACKAGE}${LIBAEC_PACKAGE_EXT}-targets.cmake
      NAMESPACE ${PACKAGE_NAMESPACE}
      COMPONENT configinstall
  )
endif ()

#-----------------------------------------------------------------------------
# Export all exported targets to the build tree for use by parent project
#-----------------------------------------------------------------------------
if (NOT LIBAEC_EXTERNALLY_CONFIGURED)
  export (
      TARGETS ${LIBAEC_LIBRARIES_TO_EXPORT} ${LIBAEC_LIB_DEPENDENCIES}
      FILE ${LIBAEC_PACKAGE}${LIBAEC_PACKAGE_EXT}-targets.cmake
      NAMESPACE ${PACKAGE_NAMESPACE}
  )
  export (PACKAGE ${LIBAEC_PACKAGE}${LIBAEC_PACKAGE_EXT})
endif ()

#-----------------------------------------------------------------------------
# Set includes needed for build
#-----------------------------------------------------------------------------
set (LIBAEC_INCLUDES_BUILD_TIME
    ${LIBAEC_SRC_DIR} ${LIBAEC_BINARY_DIR}
)

#-----------------------------------------------------------------------------
# Set variables needed for installation
#-----------------------------------------------------------------------------
set (LIBAEC_VERSION_STRING ${LIBAEC_PACKAGE_VERSION})
set (LIBAEC_VERSION_MAJOR  ${LIBAEC_PACKAGE_VERSION_MAJOR})
set (LIBAEC_VERSION_MINOR  ${LIBAEC_PACKAGE_VERSION_MINOR})

#-----------------------------------------------------------------------------
# Configure the libaec-config.cmake file for the build directory
#-----------------------------------------------------------------------------
set (INCLUDE_INSTALL_DIR ${LIBAEC_INSTALL_INCLUDE_DIR})
set (SHARE_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/${LIBAEC_INSTALL_CMAKE_DIR}" )
set (CURRENT_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}" )
configure_package_config_file (
    ${LIBAEC_RESOURCES_DIR}/libaec-config.cmake.in
    "${LIBAEC_BINARY_DIR}/${LIBAEC_PACKAGE}${LIBAEC_PACKAGE_EXT}-config.cmake"
    INSTALL_DESTINATION "${LIBAEC_INSTALL_CMAKE_DIR}/libaec"
    PATH_VARS INCLUDE_INSTALL_DIR SHARE_INSTALL_DIR CURRENT_BUILD_DIR
    INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}"
)

#-----------------------------------------------------------------------------
# Configure the libaec-config.cmake file for the install directory
#-----------------------------------------------------------------------------
set (INCLUDE_INSTALL_DIR ${LIBAEC_INSTALL_INCLUDE_DIR})
set (SHARE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/${LIBAEC_INSTALL_CMAKE_DIR}" )
set (CURRENT_BUILD_DIR "${CMAKE_INSTALL_PREFIX}")
configure_package_config_file (
    ${LIBAEC_RESOURCES_DIR}/libaec-config.cmake.in
    "${LIBAEC_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${LIBAEC_PACKAGE}${LIBAEC_PACKAGE_EXT}-config.cmake"
    INSTALL_DESTINATION "${LIBAEC_INSTALL_CMAKE_DIR}/libaec"
    PATH_VARS INCLUDE_INSTALL_DIR SHARE_INSTALL_DIR CURRENT_BUILD_DIR
)
if (NOT LIBAEC_EXTERNALLY_CONFIGURED)
  install (
      FILES ${LIBAEC_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${LIBAEC_PACKAGE}${LIBAEC_PACKAGE_EXT}-config.cmake
      DESTINATION ${LIBAEC_INSTALL_CMAKE_DIR}/libaec
      COMPONENT configinstall
  )
endif ()

#-----------------------------------------------------------------------------
# Configure the libaec-config-version.cmake file for the install directory
#-----------------------------------------------------------------------------
if (NOT LIBAEC_EXTERNALLY_CONFIGURED)
  configure_file (
      ${LIBAEC_RESOURCES_DIR}/libaec-config-version.cmake.in
      ${LIBAEC_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${LIBAEC_PACKAGE}${LIBAEC_PACKAGE_EXT}-config-version.cmake @ONLY
  )
  install (
      FILES ${LIBAEC_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${LIBAEC_PACKAGE}${LIBAEC_PACKAGE_EXT}-config-version.cmake
      DESTINATION ${LIBAEC_INSTALL_CMAKE_DIR}/libaec
      COMPONENT configinstall
  )
endif ()

#-----------------------------------------------------------------------------
# Add Document File(s) to CMake Install
#-----------------------------------------------------------------------------
if (NOT LIBAEC_EXTERNALLY_CONFIGURED)
  install (
      FILES
          ${LIBAEC_SOURCE_DIR}/Copyright.txt
          ${LIBAEC_SOURCE_DIR}/README.md
          ${LIBAEC_SOURCE_DIR}/INSTALL
          ${LIBAEC_SOURCE_DIR}/CHANGELOG.md
      DESTINATION ${LIBAEC_INSTALL_DATA_DIR}
      COMPONENT documents
  )
endif ()

#-----------------------------------------------------------------------------
# Check for Installation Utilities
#-----------------------------------------------------------------------------
if (WIN32)
  set (PF_ENV_EXT "(x86)")
  find_program (NSIS_EXECUTABLE NSIS.exe PATHS "$ENV{ProgramFiles}\\NSIS" "$ENV{ProgramFiles${PF_ENV_EXT}}\\NSIS")
  if(NOT CPACK_WIX_ROOT)
    file(TO_CMAKE_PATH "$ENV{WIX}" CPACK_WIX_ROOT)
  endif()
  find_program (WIX_EXECUTABLE candle  PATHS "${CPACK_WIX_ROOT}/bin")
endif ()

#-----------------------------------------------------------------------------
# Set the cpack variables
#-----------------------------------------------------------------------------
if (NOT LIBAEC_EXTERNALLY_CONFIGURED)
  set (CPACK_PACKAGE_VENDOR "HDF_Group")
  set (CPACK_PACKAGE_NAME "${LIBAEC_PACKAGE_NAME}")
  if (CDASH_LOCAL)
    set (CPACK_PACKAGE_VERSION "${LIBAEC_PACKAGE_VERSION}")
  else ()
    set (CPACK_PACKAGE_VERSION "${LIBAEC_PACKAGE_VERSION_STRING}")
  endif ()
  set (CPACK_PACKAGE_VERSION_MAJOR "${LIBAEC_PACKAGE_VERSION_MAJOR}")
  set (CPACK_PACKAGE_VERSION_MINOR "${LIBAEC_PACKAGE_VERSION_MINOR}")
  set (CPACK_PACKAGE_VERSION_PATCH "")
  set (CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/Copyright.txt")
  set (CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/README.SZIP")
  set (CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
  set (CPACK_PACKAGE_RELOCATABLE TRUE)
  set (CPACK_PACKAGE_DESCRIPTION_SUMMARY "libaec - Adaptive Entropy Coding library by Deutsches Klimarechenzentrum GmbH")
  set (CPACK_PACKAGE_INSTALL_DIRECTORY "${CPACK_PACKAGE_VENDOR}/${CPACK_PACKAGE_NAME}/${CPACK_PACKAGE_VERSION}")

  set (CPACK_GENERATOR "TGZ")
  if (WIN32)
    set (CPACK_GENERATOR "ZIP")

    if (NSIS_EXECUTABLE)
      list (APPEND CPACK_GENERATOR "NSIS")
    endif ()
    # Installers for 32- vs. 64-bit CMake:
    #  - Root install directory (displayed to end user at installer-run time)
    #  - "NSIS package/display name" (text used in the installer GUI)
    #  - Registry key used to store info about the installation
    set (CPACK_NSIS_PACKAGE_NAME "${LIBAEC_PACKAGE_STRING}")
    if (CMAKE_CL_64)
      set (CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES64")
      set (CPACK_PACKAGE_INSTALL_REGISTRY_KEY "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION} (Win64)")
    else ()
      set (CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES")
      set (CPACK_PACKAGE_INSTALL_REGISTRY_KEY "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}")
    endif ()
    # set the install/unistall icon used for the installer itself
    # There is a bug in NSI that does not handle full unix paths properly.
    #set (CPACK_NSIS_MUI_ICON "${LIBAEC_RESOURCES_DIR}\\\\LIBAEC.ico")
    #set (CPACK_NSIS_MUI_UNIICON "${LIBAEC_RESOURCES_DIR}\\\\LIBAEC.ico")
    # set the package header icon for MUI
    #set (CPACK_PACKAGE_ICON "${LIBAEC_RESOURCES_DIR}\\\\LIBAEC.bmp")
    set (CPACK_NSIS_DISPLAY_NAME "${CPACK_NSIS_PACKAGE_NAME}")
    set (CPACK_PACKAGE_INSTALL_DIRECTORY "${CPACK_PACKAGE_VENDOR}\\\\${CPACK_PACKAGE_NAME}\\\\${CPACK_PACKAGE_VERSION}")
    set (CPACK_NSIS_CONTACT "${LIBAEC_PACKAGE_BUGREPORT}")
    set (CPACK_NSIS_MODIFY_PATH ON)

    if (WIX_EXECUTABLE)
      list (APPEND CPACK_GENERATOR "WIX")
    endif ()
#WiX variables
    set (CPACK_WIX_UNINSTALL "1")
    set(CPACK_WIX_UPGRADE_GUID "E58A21F6-BB99-46B5-8AD8-6114E4CCA0A6")
# .. variable:: CPACK_WIX_LICENSE_RTF
#  RTF License File
#
#  If CPACK_RESOURCE_FILE_LICENSE has an .rtf extension it is used as-is.
#
#  If CPACK_RESOURCE_FILE_LICENSE has an .txt extension it is implicitly
#  converted to RTF by the WiX Generator.
#  The expected encoding of the .txt file is UTF-8.
#
#  With CPACK_WIX_LICENSE_RTF you can override the license file used by the
#  WiX Generator in case CPACK_RESOURCE_FILE_LICENSE is in an unsupported
#  format or the .txt -> .rtf conversion does not work as expected.
    set (CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/Copyright.txt")
# .. variable:: CPACK_WIX_PRODUCT_ICON
#  The Icon shown next to the program name in Add/Remove programs.
#    set(CPACK_WIX_PRODUCT_ICON "${LIBAEC_RESOURCES_DIR}\\\\hdf.ico")
#
# .. variable:: CPACK_WIX_UI_BANNER
#
#  The bitmap will appear at the top of all installer pages other than the
#  welcome and completion dialogs.
#
#  If set, this image will replace the default banner image.
#
#  This image must be 493 by 58 pixels.
#
# .. variable:: CPACK_WIX_UI_DIALOG
#
#  Background bitmap used on the welcome and completion dialogs.
#
#  If this variable is set, the installer will replace the default dialog
#  image.
#
#  This image must be 493 by 312 pixels.
#
  elseif (APPLE)
    list (APPEND CPACK_GENERATOR "STGZ")
    list (APPEND CPACK_GENERATOR "DragNDrop")
    set (CPACK_COMPONENTS_ALL_IN_ONE_PACKAGE ON)
    set (CPACK_PACKAGING_INSTALL_PREFIX "/${CPACK_PACKAGE_INSTALL_DIRECTORY}")
    #set (CPACK_PACKAGE_ICON "${LIBAEC_RESOURCES_DIR}/hdf.icns")

    option (LIBAEC_PACK_MACOSX_FRAMEWORK  "Package the LIBAEC Library in a Framework" OFF)
    if (LIBAEC_PACK_MACOSX_FRAMEWORK AND LIBAEC_BUILD_FRAMEWORKS)
      set (CPACK_BUNDLE_NAME "${LIBAEC_PACKAGE_STRING}")
      set (CPACK_BUNDLE_LOCATION "/")    # make sure CMAKE_INSTALL_PREFIX ends in /
      set (CMAKE_INSTALL_PREFIX "/${CPACK_BUNDLE_NAME}.framework/Versions/${CPACK_PACKAGE_VERSION}/${CPACK_PACKAGE_NAME}/")
      set (CPACK_SHORT_VERSION_STRING "${CPACK_PACKAGE_VERSION}")
      #-----------------------------------------------------------------------------
      # Configure the Info.plist file for the install bundle
      #-----------------------------------------------------------------------------
      configure_file (
          ${LIBAEC_RESOURCES_DIR}/CPack.Info.plist.in
          ${LIBAEC_BINARY_DIR}/CMakeFiles/Info.plist @ONLY
      )
      configure_file (
          ${LIBAEC_RESOURCES_DIR}/PkgInfo.in
          ${LIBAEC_BINARY_DIR}/CMakeFiles/PkgInfo @ONLY
      )
      install (
          FILES ${LIBAEC_BINARY_DIR}/CMakeFiles/PkgInfo
          DESTINATION ..
      )
    endif ()
  else ()
    list (APPEND CPACK_GENERATOR "STGZ")
    set (CPACK_PACKAGING_INSTALL_PREFIX "/${CPACK_PACKAGE_INSTALL_DIRECTORY}")
    set (CPACK_COMPONENTS_ALL_IN_ONE_PACKAGE ON)

    set (CPACK_DEBIAN_PACKAGE_SECTION "Libraries")
    set (CPACK_DEBIAN_PACKAGE_MAINTAINER "${LIBAEC_PACKAGE_BUGREPORT}")

#      list (APPEND CPACK_GENERATOR "RPM")
    set (CPACK_RPM_PACKAGE_RELEASE "1")
    set (CPACK_RPM_COMPONENT_INSTALL ON)
    set (CPACK_RPM_PACKAGE_RELOCATABLE ON)
  endif ()

  # By default, do not warn when built on machines using only VS Express:
  if (NOT DEFINED CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS)
    set (CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS ON)
  endif ()
  include (InstallRequiredSystemLibraries)

  set (CPACK_INSTALL_CMAKE_PROJECTS "${LIBAEC_BINARY_DIR};LIBAEC;libraries;/")
  set (CPACK_INSTALL_CMAKE_PROJECTS "${LIBAEC_BINARY_DIR};LIBAEC;headers;/")
  set (CPACK_INSTALL_CMAKE_PROJECTS "${LIBAEC_BINARY_DIR};LIBAEC;configinstall;/")

  set (CPACK_ALL_INSTALL_TYPES Full Developer User)
  set (CPACK_INSTALL_TYPE_FULL_DISPLAY_NAME "Everything")

  set(CPACK_COMPONENTS_ALL libraries headers documents configinstall)

  include (CPack)

  cpack_add_component_group(Runtime)

  cpack_add_component_group(Documents
      EXPANDED
      DESCRIPTION "Release notes for libaec"
  )

  cpack_add_component_group(Development
      EXPANDED
      DESCRIPTION "All of the tools you'll need to develop applications"
  )

  cpack_add_component (libraries
      DISPLAY_NAME "LIBAEC Libraries"
      REQUIRED
      GROUP Runtime
      INSTALL_TYPES Full Developer User
  )
  cpack_add_component (headers
      DISPLAY_NAME "LIBAEC Headers"
      DEPENDS libraries
      GROUP Development
      INSTALL_TYPES Full Developer
  )
  cpack_add_component (documents
      DISPLAY_NAME "LIBAEC Documents"
      GROUP Documents
      INSTALL_TYPES Full Developer
  )
  cpack_add_component (configinstall
      DISPLAY_NAME "LIBAEC CMake files"
      DEPENDS libraries
      GROUP Development
      INSTALL_TYPES Full Developer User
  )

endif ()
