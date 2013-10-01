# -*- Mode: CMake; indent-tabs-mode: nil; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# For copyright information, see AUTHORS.
#
# Déjà Dup is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Déjà Dup is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Déjà Dup.  If not, see <http://www.gnu.org/licenses/>.

macro(deja_check_modules)
  pkg_check_modules(${ARGV})

  # For some reason, pkg_check_modules defines _CFLAGS with semicolon separators,
  # but the COMPILE_FLAGS property takes space-separated values.  So we correct.
  # (It seems common for projects to set the specialized INCLUDE_DIRECTORIES and
  # such rather than COMPILE_FLAGS, but we have no idea what _CFLAGS might
  # contain, so we need to use it.  It won't all be includes and defines.
  # For example, -pthread is a common CFLAG from pkg-config.)
  string(REPLACE ";" " " DEJA_STRIPPED "${${ARGV0}_CFLAGS}")
  set(${ARGV0}_CFLAGS "${DEJA_STRIPPED}")

  # Same with _LDFLAGS
  string(REPLACE ";" " " DEJA_STRIPPED "${${ARGV0}_LDFLAGS}")
  set(${ARGV0}_LDFLAGS "${DEJA_STRIPPED}")
endmacro()

macro(deja_find_required_program VAR PROGRAM)
  find_program(${VAR} ${PROGRAM})
  if(NOT ${VAR})
    message(FATAL_ERROR "Could not find ${PROGRAM}")
  endif()
endmacro()

find_program(DESKTOP_FILE_VALIDATE desktop-file-validate)
macro(deja_test_desktop DESKTOP_FILE)
  if(DESKTOP_FILE_VALIDATE)
    add_test(validate-${DESKTOP_FILE} ${DESKTOP_FILE_VALIDATE} ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE})
  endif()
endmacro()

function(deja_merge_po STYLE OUTPUT DESTINATION)
  cmake_parse_arguments(deja "NO_MERGE" "" "" ${ARGN})
  if(deja_NO_MERGE)
    set(TRANSLATION_ARGS "--no-translations")
  else()
    set(TRANSLATION_ARGS "${CMAKE_SOURCE_DIR}/po")
  endif()

  configure_file(${OUTPUT}.in ${OUTPUT}.vars @ONLY)
  add_custom_target(${OUTPUT} ALL
                    ${INTLTOOL_MERGE} --${STYLE}-style -u -q ${TRANSLATION_ARGS}
                                      -c ${CMAKE_BINARY_DIR}/po/.intltool-merge-cache
                                      ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT}.vars
                                      ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT}
                    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT}.vars)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT} DESTINATION ${DESTINATION})

  if((${STYLE} STREQUAL desktop) AND DESKTOP_FILE_VALIDATE)
    add_test(validate-${OUTPUT} ${DESKTOP_FILE_VALIDATE} ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT})
  endif()
endfunction()
