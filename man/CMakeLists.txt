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

file(GLOB POFILES RELATIVE ${CMAKE_SOURCE_DIR}/po ${CMAKE_SOURCE_DIR}/po/*.po)
string(REPLACE ".po" "" LINGUAS "${POFILES}")

add_custom_command(OUTPUT C/deja-dup.1 C/deja-dup-preferences.1
                   COMMAND mkdir -p C
                   COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/help2man -N -i ${CMAKE_CURRENT_SOURCE_DIR}/include.main -L en_US.UTF-8 ${CMAKE_BINARY_DIR}/deja-dup/deja-dup -o C/deja-dup.1
                   COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/help2man -N -i ${CMAKE_CURRENT_SOURCE_DIR}/include.pref -L en_US.UTF-8 ${CMAKE_BINARY_DIR}/deja-dup/preferences/deja-dup-preferences -o C/deja-dup-preferences.1
                   DEPENDS deja-dup deja-dup-preferences)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/C/deja-dup.1 ${CMAKE_CURRENT_BINARY_DIR}/C/deja-dup-preferences.1 DESTINATION "${CMAKE_INSTALL_FULL_DATADIR}/man/man1")
list(APPEND MAN_TARGETS C/deja-dup.1 C/deja-dup-preferences.1)

foreach(LINGUA ${LINGUAS})
  add_custom_command(OUTPUT ${LINGUA}/deja-dup.1 ${LINGUA}/deja-dup-preferences.1
                     COMMAND mkdir -p ${LINGUA} locales/${LINGUA}/LC_MESSAGES
                     COMMAND ln -sf ${CMAKE_BINARY_DIR}/po/${LINGUA}.gmo locales/${LINGUA}/LC_MESSAGES/deja-dup.mo
                     COMMAND env DEJA_DUP_LOCALEDIR=${CMAKE_CURRENT_BINARY_DIR}/locales DEJA_DUP_LANGUAGE=${LINGUA} ${CMAKE_CURRENT_SOURCE_DIR}/help2man -N -i ${CMAKE_CURRENT_SOURCE_DIR}/include.main -L en_US.UTF-8 ${CMAKE_BINARY_DIR}/deja-dup/deja-dup -o ${LINGUA}/deja-dup.1
                     COMMAND env DEJA_DUP_LOCALEDIR=${CMAKE_CURRENT_BINARY_DIR}/locales DEJA_DUP_LANGUAGE=${LINGUA} ${CMAKE_CURRENT_SOURCE_DIR}/help2man -N -i ${CMAKE_CURRENT_SOURCE_DIR}/include.main -L en_US.UTF-8 ${CMAKE_BINARY_DIR}/deja-dup/preferences/deja-dup-preferences -o ${LINGUA}/deja-dup-preferences.1
                     DEPENDS translations deja-dup deja-dup-preferences)

  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}/deja-dup.1 ${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}/deja-dup-preferences.1 DESTINATION "${CMAKE_INSTALL_FULL_DATADIR}/man/${LINGUA}/man1")

  list(APPEND MAN_TARGETS ${LINGUA}/deja-dup.1 ${LINGUA}/deja-dup-preferences.1)
endforeach ()

add_custom_target(man ALL DEPENDS ${MAN_TARGETS})
