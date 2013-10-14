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

if(BUILD_TESTING)

vala_precompile(VALA_C_UNIT_TESTS unit-tests.vala
                PACKAGES gio-2.0 libpeas-1.0 libsecret-1 posix
                CUSTOM_VAPIS ${CMAKE_BINARY_DIR}/libdeja/deja.vapi
                             ${CMAKE_SOURCE_DIR}/vapi/config.vapi
                OPTIONS ${COMMON_VFLAGS})
add_executable(unit-tests ${VALA_C_UNIT_TESTS})
target_link_libraries(unit-tests deja ${GLIB_LDFLAGS} ${PEAS_LDFLAGS} ${SECRET_LDFLAGS})
set_target_properties(unit-tests PROPERTIES
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${PEAS_CFLAGS} ${SECRET_CFLAGS} ${COMMON_CFLAGS}"
                      INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/libdeja")
add_test(unit-tests env top_builddir=${CMAKE_BINARY_DIR} srcdir=${CMAKE_CURRENT_SOURCE_DIR} dbus-launch ./unit-tests)

# The network test is manual for the moment
vala_precompile(VALA_C_NETWORK_TEST network.vala
                PACKAGES gio-2.0 libpeas-1.0 libsecret-1
                CUSTOM_VAPIS ${CMAKE_BINARY_DIR}/libdeja/deja.vapi
                             ${CMAKE_SOURCE_DIR}/vapi/config.vapi
                OPTIONS "${COMMON_VFLAGS}")
add_executable(network-test ${VALA_C_UNIT_TESTS})
target_link_libraries(network-test deja ${GLIB_LDFLAGS} ${PEAS_LDFLAGS} ${SECRET_LDFLAGS})
set_target_properties(network-test PROPERTIES
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${PEAS_CFLAGS} ${SECRET_CFLAGS} ${COMMON_CFLAGS}"
                      INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/libdeja")

endif(BUILD_TESTING)
