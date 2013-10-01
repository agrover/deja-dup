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

file(GLOB POFILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.po)
string(REPLACE ".po" "" LINGUAS "${POFILES}")

foreach(LINGUA ${LINGUAS})
  add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}.gmo"
                     COMMAND ${MSGFMT} -o ${LINGUA}.gmo "${CMAKE_CURRENT_SOURCE_DIR}/${LINGUA}.po"
                     DEPENDS ${LINGUA}.po)
  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}.gmo" DESTINATION "${CMAKE_INSTALL_FULL_LOCALEDIR}/${LINGUA}/LC_MESSAGES" RENAME ${GETTEXT_PACKAGE}.mo)
  list(APPEND LINGUA_TARGETS "${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}.gmo")
endforeach()
add_custom_target(translations ALL DEPENDS ${LINGUA_TARGETS})

find_program(INTLTOOL_UPDATE intltool-update)
if(INTLTOOL_UPDATE)
add_custom_target(${GETTEXT_PACKAGE}.pot
                  COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR} && ${INTLTOOL_UPDATE} --pot --gettext-package=${GETTEXT_PACKAGE})
endif()
