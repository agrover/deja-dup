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

deja_find_required_program(ITSTOOL itstool)
find_program(XMLLINT xmllint)

file(GLOB C_PAGES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} C/*.page)
file(GLOB POFILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} */*.po)
string(REGEX REPLACE "(^|;)([^/]+)/[^;]*" "\\2" LINGUAS "${POFILES}")

install(FILES ${C_PAGES} DESTINATION "${CMAKE_INSTALL_FULL_DATADIR}/help/C/${PACKAGE}")

foreach(LINGUA ${LINGUAS})
  string(REPLACE "C/" "${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}/" LINGUA_PAGES "${C_PAGES}")
  add_custom_command(OUTPUT ${LINGUA_PAGES}
                     COMMAND mkdir -p "${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}"
                     COMMAND ${MSGFMT} -o "${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}/${LINGUA}.gmo" ${LINGUA}/${LINGUA}.po
                     COMMAND ${ITSTOOL} -m "${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}/${LINGUA}.gmo" -o "${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}" ${C_PAGES}
                     WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                     DEPENDS ${LINGUA}/${LINGUA}.po ${C_PAGES})
  if(XMLLINT)
    add_test(validate-help-${LINGUA} ${XMLLINT} --noent --noout ${LINGUA_PAGES})
  endif()
  install(FILES ${LINGUA_PAGES} DESTINATION "${CMAKE_INSTALL_FULL_DATADIR}/help/${LINGUA}/${PACKAGE}")
  list(APPEND LINGUA_TARGETS ${LINGUA_PAGES})
endforeach()
add_custom_target(${PACKAGE}-help ALL DEPENDS ${LINGUA_TARGETS})

add_custom_target(${PACKAGE}-help.pot
                  COMMAND ${ITSTOOL} -o ${PACKAGE}-help.pot ${C_PAGES}
                  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
