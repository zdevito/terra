include(FindPackageHandleStandardArgs)

set(TERRA_LUA "luajit" CACHE STRING "Build Terra against the specified Lua implementation")

if(TERRA_LUA STREQUAL "luajit")
  set(LUAJIT_NAME "LuaJIT")
  set(LUAJIT_BASE "luajit")
  set(LUAJIT_VERSION_MAJOR 2)
  set(LUAJIT_VERSION_MINOR 1)
  set(LUAJIT_VERSION_PATCH 0)
  set(LUAJIT_VERSION_EXTRA -beta3)
  set(LUAJIT_COMMIT "9143e86498436892cb4316550be4d45b68a61224")
  if(NOT LUAJIT_VERSION_COMMIT STREQUAL "")
    set(LUAJIT_URL_PREFIX "https://github.com/LuaJIT/LuaJIT/archive/")
  else()
    set(LUAJIT_URL_PREFIX "https://luajit.org/download/")
  endif()
elseif(TERRA_LUA STREQUAL "moonjit")
  set(LUAJIT_NAME "moonjit")
  set(LUAJIT_BASE "moonjit")
  set(LUAJIT_VERSION_MAJOR 2)
  set(LUAJIT_VERSION_MINOR 3)
  set(LUAJIT_VERSION_PATCH 0)
  set(LUAJIT_VERSION_EXTRA -dev)
  set(LUAJIT_COMMIT "eb7168839138591e0d2a1751122966603a8b87c8")
  set(LUAJIT_URL_PREFIX "https://github.com/moonjit/moonjit/archive/")
elseif(TERRA_LUA STREQUAL "external")
  set(LUAJIT_NAME "LuaJIT")
  set(LUAJIT_BASE "luajit")
  if(DEFINED EXTERNAL_LUAJIT_VERSION)
    string(REGEX MATCHALL
      "^([0-9]+)\.([0-9]+)\.([0-9]+)(-.*)$"
      LUAJIT_VERSION_PARTS EXTERNAL_LUAJIT_VERSION)
    set(LUAJIT_VERSION_MAJOR ${CMAKE_MATCH_1})
    set(LUAJIT_VERSION_MINOR ${CMAKE_MATCH_2})
    set(LUAJIT_VERSION_PATCH ${CMAKE_MATCH_3})
    set(LUAJIT_VERSION_EXTRA ${CMAKE_MATCH_4})
  endif()
else()
  message(FATAL_ERROR "TERRA_LUA must be one of 'luajit', 'moonjit', 'external'")
endif()
if(NOT LUAJIT_COMMIT STREQUAL "")
  set(LUAJIT_BASENAME "${LUAJIT_NAME}-${LUAJIT_COMMIT}")
  set(LUAJIT_URL "${LUAJIT_URL_PREFIX}/${LUAJIT_COMMIT}.tar.gz")
else()
  set(LUAJIT_BASENAME "${LUAJIT_NAME}-${LUAJIT_VERSION_MAJOR}.${LUAJIT_VERSION_MINOR}.${LUAJIT_VERSION_PATCH}${LUAJIT_VERSION_EXTRA}")
  set(LUAJIT_URL "${LUAJIT_URL_PREFIX}/${LUAJIT_BASENAME}.tar.gz")
endif()

if(NOT TERRA_LUA STREQUAL "external")
  set(LUAJIT_TAR "${PROJECT_BINARY_DIR}/${LUAJIT_BASENAME}.tar.gz")
else()
  set(LUAJIT_TAR "${PROJECT_BINARY_DIR}/${LUAJIT_TARNAME}")
endif()

if(LUAJIT_COMMIT STREQUAL "")
  set(LUAJIT_SOURCE_DIR "${PROJECT_BINARY_DIR}/${LUAJIT_BASENAME}" CACHE STRING "")
else()
  set(LUAJIT_SOURCE_DIR "${PROJECT_BINARY_DIR}/${LUAJIT_COMMIT}" CACHE STRING "")
endif()

set(LUAJIT_HEADER_BASENAMES lua.h lualib.h lauxlib.h luaconf.h)

if(WIN32)
  set(LUAJIT_INSTALL_PREFIX "${LUAJIT_SOURCE_DIR}/src")
  set(LUAJIT_INCLUDE_DIR "${LUAJIT_INSTALL_PREFIX}")
  set(LUAJIT_LIBRARY_NAME_WE "${LUAJIT_INSTALL_PREFIX}/lua51")
  set(LUAJIT_EXECUTABLE "${LUAJIT_INSTALL_PREFIX}/luajit.exe")
else()
  set(LUAJIT_INSTALL_PREFIX "${PROJECT_BINARY_DIR}/${LUAJIT_BASE}")
  set(LUAJIT_INCLUDE_DIR "${LUAJIT_INSTALL_PREFIX}/include/${LUAJIT_BASE}-${LUAJIT_VERSION_MAJOR}.${LUAJIT_VERSION_MINOR}")
  set(LUAJIT_SHARE_DIR "${LUAJIT_INSTALL_PREFIX}/share/${LUAJIT_BASE}-${LUAJIT_VERSION_MAJOR}.${LUAJIT_VERSION_MINOR}.${LUAJIT_VERSION_PATCH}${LUAJIT_VERSION_EXTRA}")
  set(LUAJIT_LIBRARY_NAME_WE "${LUAJIT_INSTALL_PREFIX}/lib/libluajit-5.1")
  set(LUAJIT_EXECUTABLE "${LUAJIT_INSTALL_PREFIX}/bin/${LUAJIT_BASE}-${LUAJIT_VERSION_MAJOR}.${LUAJIT_VERSION_MINOR}.${LUAJIT_VERSION_PATCH}${LUAJIT_VERSION_EXTRA}")
endif()

string(CONCAT
  LUAJIT_STATIC_LIBRARY
  "${LUAJIT_LIBRARY_NAME_WE}"
  "${CMAKE_STATIC_LIBRARY_SUFFIX}"
)

string(CONCAT
  LUAJIT_SHARED_LIBRARY
  "${LUAJIT_LIBRARY_NAME_WE}"
  "${CMAKE_SHARED_LIBRARY_SUFFIX}"
)

if(NOT TERRA_LUA STREQUAL "external")
  file(DOWNLOAD "${LUAJIT_URL}" "${LUAJIT_TAR}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E tar xzf "${LUAJIT_TAR}"
  WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
)

foreach(LUAJIT_HEADER ${LUAJIT_HEADER_BASENAMES})
  list(APPEND LUAJIT_INSTALL_HEADERS "${LUAJIT_INCLUDE_DIR}/${LUAJIT_HEADER}")
endforeach()

list(APPEND LUAJIT_SHARED_LIBRARY_PATHS
  "${LUAJIT_SHARED_LIBRARY}"
)
if(UNIX AND NOT APPLE)
  list(APPEND LUAJIT_SHARED_LIBRARY_PATHS
    "${LUAJIT_SHARED_LIBRARY}.${LUAJIT_VERSION_MAJOR}"
    "${LUAJIT_SHARED_LIBRARY}.${LUAJIT_VERSION_MAJOR}.${LUAJIT_VERSION_MINOR}.${LUAJIT_VERSION_PATCH}"
  )
endif()

if(WIN32)
  add_custom_command(
    OUTPUT ${LUAJIT_STATIC_LIBRARY} ${LUAJIT_SHARED_LIBRARY_PATHS} ${LUAJIT_EXECUTABLE}
    DEPENDS ${LUAJIT_INSTALL_HEADERS}
    COMMAND msvcbuild
    WORKING_DIRECTORY ${LUAJIT_SOURCE_DIR}/src
    VERBATIM
  )

  install(
    FILES ${LUAJIT_SHARED_LIBRARY_PATHS}
    DESTINATION ${CMAKE_INSTALL_BINDIR}
  )

  install(
    FILES ${LUAJIT_STATIC_LIBRARY}
    DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

  file(MAKE_DIRECTORY "${LUAJIT_INSTALL_PREFIX}/lua/jit")

  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar tzf "${LUAJIT_TAR}"
    OUTPUT_VARIABLE LUAJIT_TAR_CONTENTS
  )

  string(REGEX MATCHALL
    "[^\\\\/\r\n]+/src/jit/[^\\\\/\r\n]+[.]lua"
    LUAJIT_LUA_SOURCE_PATHS
    ${LUAJIT_TAR_CONTENTS}
  )

  foreach(LUAJIT_SOURCE_PATH ${LUAJIT_LUA_SOURCE_PATHS})
    string(REGEX MATCH
      "[^\\\\/\r\n]+[.]lua"
      LUAJIT_SOURCE_NAME
      ${LUAJIT_SOURCE_PATH}
    )
    file(COPY "${LUAJIT_INSTALL_PREFIX}/jit/${LUAJIT_SOURCE_NAME}"
      DESTINATION "${LUAJIT_INSTALL_PREFIX}/lua/jit/"
    )
    list(APPEND LUAJIT_LUA_SOURCES
      "${LUAJIT_INSTALL_PREFIX}/lua/jit/${LUAJIT_SOURCE_NAME}"
    )
  endforeach()
else()
  add_custom_command(
    OUTPUT ${LUAJIT_STATIC_LIBRARY} ${LUAJIT_SHARED_LIBRARY_PATHS} ${LUAJIT_EXECUTABLE} ${LUAJIT_INSTALL_HEADERS}
    DEPENDS ${LUAJIT_SOURCE_DIR}
    # MACOSX_DEPLOYMENT_TARGET is a workaround for https://github.com/LuaJIT/LuaJIT/issues/484
    # see also https://github.com/LuaJIT/LuaJIT/issues/575
    COMMAND make install "PREFIX=${LUAJIT_INSTALL_PREFIX}" "CC=${CMAKE_C_COMPILER}" "STATIC_CC=${CMAKE_C_COMPILER} -fPIC" XCFLAGS=-DLUAJIT_ENABLE_GC64 MACOSX_DEPLOYMENT_TARGET=10.7
    WORKING_DIRECTORY ${LUAJIT_SOURCE_DIR}
    VERBATIM
  )
endif()

foreach(LUAJIT_HEADER ${LUAJIT_HEADER_BASENAMES})
  list(APPEND LUAJIT_HEADERS ${PROJECT_BINARY_DIR}/include/terra/${LUAJIT_HEADER})
endforeach()

foreach(LUAJIT_HEADER ${LUAJIT_HEADER_BASENAMES})
  if(WIN32)
    file(COPY "${LUAJIT_INCLUDE_DIR}/${LUAJIT_HEADER}"
      DESTINATION "${PROJECT_BINARY_DIR}/include/terra/"
    )
  else()
    add_custom_command(
      OUTPUT ${PROJECT_BINARY_DIR}/include/terra/${LUAJIT_HEADER}
      DEPENDS
        ${LUAJIT_INCLUDE_DIR}/${LUAJIT_HEADER}
      COMMAND "${CMAKE_COMMAND}" -E copy "${LUAJIT_INCLUDE_DIR}/${LUAJIT_HEADER}" "${PROJECT_BINARY_DIR}/include/terra/"
      VERBATIM
    )
  endif()
  install(
    FILES ${PROJECT_BINARY_DIR}/include/terra/${LUAJIT_HEADER}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/terra
  )
endforeach()

if(TERRA_SLIB_INCLUDE_LUAJIT)
  set(LUAJIT_OBJECT_DIR "${PROJECT_BINARY_DIR}/lua_objects")
  file(MAKE_DIRECTORY "${LUAJIT_OBJECT_DIR}")

  # Since we need the list of objects at configure time, best we can do
  # (without building LuaJIT right this very second) is to guess based
  # on the source files contained in the release tarball.
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar tzf "${LUAJIT_TAR}"
    OUTPUT_VARIABLE LUAJIT_TAR_CONTENTS
  )

  string(REGEX MATCHALL
    "[^/\n]+/src/l[ij][b_][^\n]+[.]c"
    LUAJIT_SOURCES
    ${LUAJIT_TAR_CONTENTS}
  )

  foreach(LUAJIT_SOURCE ${LUAJIT_SOURCES})
    string(REGEX MATCH
      "[^/\n]+[.]c"
      LUAJIT_SOURCE_BASENAME
      ${LUAJIT_SOURCE}
    )
    string(REGEX REPLACE
      [.]c .o
      LUAJIT_OBJECT_BASENAME
      ${LUAJIT_SOURCE_BASENAME}
    )
    list(APPEND LUAJIT_OBJECT_BASENAMES ${LUAJIT_OBJECT_BASENAME})
  endforeach()
  list(APPEND LUAJIT_OBJECT_BASENAMES lj_vm.o)

  foreach(LUAJIT_OBJECT ${LUAJIT_OBJECT_BASENAMES})
    list(APPEND LUAJIT_OBJECTS "${LUAJIT_OBJECT_DIR}/${LUAJIT_OBJECT}")
  endforeach()

  add_custom_command(
    OUTPUT ${LUAJIT_OBJECTS}
    DEPENDS ${LUAJIT_STATIC_LIBRARY}
    COMMAND "${CMAKE_AR}" x "${LUAJIT_STATIC_LIBRARY}"
    WORKING_DIRECTORY ${LUAJIT_OBJECT_DIR}
    VERBATIM
  )

  # Don't link libraries, since we're using the extracted object files.
  list(APPEND LUAJIT_LIBRARIES)
elseif(TERRA_STATIC_LINK_LUAJIT)
  if(APPLE)
    list(APPEND LUAJIT_LIBRARIES "-Wl,-force_load,${LUAJIT_STATIC_LIBRARY}")
  elseif(UNIX)
    list(APPEND LUAJIT_LIBRARIES
      -Wl,-export-dynamic
      -Wl,--whole-archive
      "${LUAJIT_STATIC_LIBRARY}"
      -Wl,--no-whole-archive
    )
  else()
    list(APPEND LUAJIT_LIBRARIES ${LUAJIT_STATIC_LIBRARY})
  endif()

  # Don't extract individual object files.
  list(APPEND LUAJIT_OBJECTS)
else()
  list(APPEND LUAJIT_LIBRARIES ${LUAJIT_SHARED_LIBRARY})

  # Make a copy of the LuaJIT shared library into the local build and
  # install so that all the directory structures are consistent.
  # Note: Need to copy all symlinks (*.so.0 etc.).
  foreach(LUAJIT_SHARED_LIBRARY_PATH ${LUAJIT_SHARED_LIBRARY_PATHS})
    get_filename_component(LUAJIT_SHARED_LIBRARY_NAME "${LUAJIT_SHARED_LIBRARY_PATH}" NAME)
    add_custom_command(
      OUTPUT ${PROJECT_BINARY_DIR}/lib/${LUAJIT_SHARED_LIBRARY_NAME}
      DEPENDS ${LUAJIT_SHARED_LIBRARY_PATH}
      COMMAND "${CMAKE_COMMAND}" -E copy "${LUAJIT_SHARED_LIBRARY_PATH}" "${PROJECT_BINARY_DIR}/lib/${LUAJIT_SHARED_LIBRARY_NAME}"
      VERBATIM
    )
    list(APPEND LUAJIT_SHARED_LIBRARY_BUILD_PATHS
      ${PROJECT_BINARY_DIR}/lib/${LUAJIT_SHARED_LIBRARY_NAME}
    )

    install(
      FILES ${LUAJIT_SHARED_LIBRARY_PATH}
      DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )
  endforeach()

  # Don't extract individual object files.
  list(APPEND LUAJIT_OBJECTS)
endif()

add_custom_target(
  LuaJIT
  DEPENDS
    ${LUAJIT_STATIC_LIBRARY}
    ${LUAJIT_SHARED_LIBRARY_PATHS}
    ${LUAJIT_SHARED_LIBRARY_BUILD_PATHS}
    ${LUAJIT_EXECUTABLE}
    ${LUAJIT_HEADERS}
    ${LUAJIT_OBJECTS}
)

mark_as_advanced(
  LUAJIT_BASENAME
  LUAJIT_URL
  LUAJIT_TAR
  LUAJIT_SOURCE_DIR
  LUAJIT_INCLUDE_DIR
  LUAJIT_HEADER_BASENAMES
  LUAJIT_OBJECT_DIR
  LUAJIT_LIBRARY
  LUAJIT_EXECUTABLE
)
