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

vala_precompile(VALA_C DuplicityInstance.vala
                       DuplicityJob.vala
                       DuplicityPlugin.vala
                PACKAGES gio-2.0 gio-unix-2.0 libpeas-1.0 libsecret-1 posix
                CUSTOM_VAPIS ${CMAKE_BINARY_DIR}/libdeja/deja.vapi
                             ${CMAKE_SOURCE_DIR}/vapi/config.vapi
                OPTIONS ${COMMON_VFLAGS})
add_library(duplicity MODULE ${VALA_C})
target_link_libraries(duplicity deja ${GLIB_LDFLAGS} ${PEAS_LDFLAGS} ${SECRET_LDFLAGS})
set_target_properties(duplicity PROPERTIES
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${PEAS_CFLAGS} ${SECRET_CFLAGS} ${COMMON_CFLAGS}")
install(TARGETS duplicity DESTINATION "${PKG_LIBEXECDIR}/tools")

configure_file(duplicity.plugin duplicity.plugin COPYONLY) # for script tests
install(FILES duplicity.plugin DESTINATION "${PKG_LIBEXECDIR}/tools")
