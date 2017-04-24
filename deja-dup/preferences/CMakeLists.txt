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

vala_precompile(VALA_C preferences-main.vala
                       Preferences.vala
                PACKAGES gtk+-3.0 libpeas-1.0 libsecret-1
                CUSTOM_VAPIS ${CMAKE_BINARY_DIR}/libdeja/deja.vapi
                             ${CMAKE_BINARY_DIR}/deja-dup/widgets/widgets.vapi
                             ${CMAKE_SOURCE_DIR}/vapi/config.vapi
                             ${CMAKE_SOURCE_DIR}/vapi/packagekit-glib2.vapi
                OPTIONS ${COMMON_VFLAGS})
add_executable(deja-dup-preferences ${VALA_C})
target_link_libraries(deja-dup-preferences deja widgets ${GTK_LDFLAGS} ${NOTIFY_LDFLAGS} ${PEAS_LDFLAGS} ${PK_LDFLAGS} ${SECRET_LDFLAGS})
set_target_properties(deja-dup-preferences PROPERTIES
                      INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/libdeja;${CMAKE_BINARY_DIR}/deja-dup/widgets"
                      COMPILE_FLAGS "${GTK_CFLAGS} ${PEAS_CFLAGS} ${PK_CFLAGS} ${SECRET_CFLAGS} ${COMMON_CFLAGS}")
install(TARGETS deja-dup-preferences DESTINATION bin)

deja_merge_po(desktop deja-dup-preferences.desktop "${CMAKE_INSTALL_FULL_DATADIR}/applications")
