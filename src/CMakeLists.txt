cmake_minimum_required (VERSION 3.10)
project (LIBAEC_SRC C)

include (GenerateExportHeader)

#-----------------------------------------------------------------------------
# Define LIBAEC Library
#-----------------------------------------------------------------------------
set(LIBAEC_SRCS
    ${LIBAEC_SRC_SOURCE_DIR}/encode.c
    ${LIBAEC_SRC_SOURCE_DIR}/encode_accessors.c
    ${LIBAEC_SRC_SOURCE_DIR}/decode.c
)

set (LIBAEC_PUBLIC_HEADERS
    ${LIBAEC_SRC_SOURCE_DIR}/libaec.h
)

add_library (${LIBAEC_LIB_TARGET} STATIC ${LIBAEC_SRCS} ${LIBAEC_PUBLIC_HEADERS})
target_include_directories (${LIBAEC_LIB_TARGET} PRIVATE "${LIBAEC_SOURCE_DIR};${CMAKE_BINARY_DIR}")
TARGET_C_PROPERTIES (${LIBAEC_LIB_TARGET} STATIC)
target_link_libraries (${LIBAEC_LIB_TARGET} PRIVATE ${LINK_LIBS})
LIBAEC_SET_LIB_OPTIONS (${LIBAEC_LIB_TARGET} ${LIBAEC_LIB_NAME} STATIC)
set_target_properties (${LIBAEC_LIB_TARGET} PROPERTIES
    VERSION 0.0.10 SOVERSION 0
    PUBLIC_HEADER "${LIBAEC_PUBLIC_HEADERS}"
    LINKER_LANGUAGE C
    INTERFACE_INCLUDE_DIRECTORIES "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include>"
)
set_global_variable (LIBAEC_LIBRARIES_TO_EXPORT ${LIBAEC_LIB_TARGET})
set (install_targets ${LIBAEC_LIB_TARGET})

generate_export_header (${LIBAEC_LIB_TARGET}
    BASE_NAME libaec
    EXPORT_MACRO_NAME libaec_EXPORT
    EXPORT_FILE_NAME ${CMAKE_BINARY_DIR}/libaec_Export.h
    STATIC_DEFINE libaec_BUILT_AS_STATIC
)
if (BUILD_SHARED_LIBS)
  add_library (${LIBAEC_LIBSH_TARGET} SHARED ${LIBAEC_SRCS} ${LIBAEC_PUBLIC_HEADERS})
  target_include_directories (${LIBAEC_LIBSH_TARGET} PRIVATE "${LIBAEC_SOURCE_DIR};${CMAKE_BINARY_DIR}")
  TARGET_C_PROPERTIES (${LIBAEC_LIBSH_TARGET} SHARED)
  target_link_libraries (${LIBAEC_LIBSH_TARGET} PRIVATE ${LINK_LIBS})
  LIBAEC_SET_LIB_OPTIONS (${LIBAEC_LIBSH_TARGET} ${LIBAEC_LIB_NAME} SHARED)
  set_target_properties (${LIBAEC_LIBSH_TARGET} PROPERTIES
      VERSION 0.0.10 SOVERSION 0
      PUBLIC_HEADER "${LIBAEC_PUBLIC_HEADERS}"
      LINKER_LANGUAGE C
      INTERFACE_INCLUDE_DIRECTORIES "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include>"
  )
  if (WIN32)
    set_target_properties (${LIBAEC_LIB_TARGET} PROPERTIES DEFINE_SYMBOL "BUILDING_LIBAEC")
  endif ()
  set_global_variable (LIBAEC_LIBRARIES_TO_EXPORT "${LIBAEC_LIBRARIES_TO_EXPORT};${LIBAEC_LIBSH_TARGET}")
  set (install_targets ${install_targets} ${LIBAEC_LIBSH_TARGET})
endif ()

set(SZIP_SRCS
    ${LIBAEC_SRC_SOURCE_DIR}/sz_compat.c
)

set (SZIP_PUBLIC_HEADERS
    ${LIBAEC_SRC_SOURCE_DIR}/szlib.h
)

add_library (${SZIP_LIB_TARGET} STATIC ${SZIP_SRCS} ${SZIP_PUBLIC_HEADERS})
target_include_directories (${SZIP_LIB_TARGET} PRIVATE "${LIBAEC_SOURCE_DIR};${CMAKE_BINARY_DIR}")
TARGET_C_PROPERTIES (${SZIP_LIB_TARGET} STATIC)
target_link_libraries (${SZIP_LIB_TARGET} PRIVATE ${LIBAEC_LIB_TARGET})
LIBAEC_SET_LIB_OPTIONS (${SZIP_LIB_TARGET} ${SZIP_LIB_NAME} STATIC)
set_target_properties (${SZIP_LIB_TARGET} PROPERTIES VERSION 2.0.1 SOVERSION 2)
set_target_properties (${SZIP_LIB_TARGET} PROPERTIES
    VERSION 2.0.1 SOVERSION 2
    PUBLIC_HEADER "${LIBAEC_PUBLIC_HEADERS}"
    LINKER_LANGUAGE C
    INTERFACE_INCLUDE_DIRECTORIES "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include>"
)
set_global_variable (LIBAEC_LIBRARIES_TO_EXPORT "${LIBAEC_LIBRARIES_TO_EXPORT};${SZIP_LIB_TARGET}")
set (install_targets ${install_targets} ${SZIP_LIB_TARGET})
if (BUILD_SHARED_LIBS)
  add_library (${SZIP_LIBSH_TARGET} SHARED ${SZIP_SRCS} ${SZIP_PUBLIC_HEADERS})
  target_include_directories (${SZIP_LIBSH_TARGET} PRIVATE "${SZIP_SOURCE_DIR};${CMAKE_BINARY_DIR}")
  TARGET_C_PROPERTIES (${SZIP_LIBSH_TARGET} SHARED)
  target_link_libraries (${SZIP_LIBSH_TARGET} PRIVATE ${LIBAEC_LIBSH_TARGET})
  LIBAEC_SET_LIB_OPTIONS (${SZIP_LIBSH_TARGET} ${SZIP_LIB_NAME} SHARED)
  set_target_properties (${SZIP_LIBSH_TARGET} PROPERTIES
      VERSION 2.0.1 SOVERSION 2
      PUBLIC_HEADER "${SZIP_PUBLIC_HEADERS}"
      LINKER_LANGUAGE C
      INTERFACE_INCLUDE_DIRECTORIES "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include>"
  )
  if (WIN32)
    set_target_properties (${SZIP_LIB_TARGET} PROPERTIES DEFINE_SYMBOL "BUILDING_LIBAEC")
  endif ()
  set_global_variable (LIBAEC_LIBRARIES_TO_EXPORT "${LIBAEC_LIBRARIES_TO_EXPORT};${SZIP_LIBSH_TARGET}")
  set (install_targets ${install_targets} ${SZIP_LIBSH_TARGET})
endif ()

if (BUILD_TESTING)
  add_executable (aec_client aec.c)
  set_target_properties (aec_client PROPERTIES OUTPUT_NAME "aec")
  target_link_libraries (aec_client ${LIBAEC_LIB_TARGET})

  if (UNIX)
    add_executable (utime EXCLUDE_FROM_ALL utime.c)
    add_custom_target (bench
        COMMAND ${LIBAEC_SRC_SOURCE_DIR}/benc.sh ${CMAKE_SOURCE_DIR}/data/typical.rz
        COMMAND ${LIBAEC_SRC_SOURCE_DIR}/bdec.sh
        DEPENDS aec_client utime)
  endif ()
endif ()

if (NOT SKIP_INSTALL_FILES AND NOT SKIP_INSTALL_ALL)
  install (FILES aec.1 DESTINATION share/man/man3 COMPONENT documents)
endif ()

install(FILES ${CMAKE_BINARY_DIR}/libaec_Export.h
    DESTINATION ${LIBAEC_INSTALL_INCLUDE_DIR}
    COMPONENT headers
)

#-----------------------------------------------------------------------------
# Add Target(s) to CMake Install for import into other projects
#-----------------------------------------------------------------------------
if (LIBAEC_EXPORTED_TARGETS)
  if (BUILD_SHARED_LIBS)
    INSTALL_TARGET_PDB (${LIBAEC_LIBSH_TARGET} ${LIBAEC_INSTALL_BIN_DIR} libraries)
    INSTALL_TARGET_PDB (${SZIP_LIBSH_TARGET} ${LIBAEC_INSTALL_BIN_DIR} libraries)
  endif (BUILD_SHARED_LIBS)
  INSTALL_TARGET_PDB (${LIBAEC_LIB_TARGET} ${LIBAEC_INSTALL_BIN_DIR} libraries)
  INSTALL_TARGET_PDB (${SZIP_LIB_TARGET} ${LIBAEC_INSTALL_BIN_DIR} libraries)

  install (
      TARGETS
          ${install_targets}
      EXPORT
          ${LIBAEC_EXPORTED_TARGETS}
      LIBRARY DESTINATION ${LIBAEC_INSTALL_LIB_DIR} COMPONENT libraries
      ARCHIVE DESTINATION ${LIBAEC_INSTALL_LIB_DIR} COMPONENT libraries
      RUNTIME DESTINATION ${LIBAEC_INSTALL_BIN_DIR} COMPONENT libraries
      FRAMEWORK DESTINATION ${LIBAEC_INSTALL_FWRK_DIR} COMPONENT libraries
      PUBLIC_HEADER DESTINATION ${LIBAEC_INSTALL_INCLUDE_DIR} COMPONENT headers
  )
endif ()
