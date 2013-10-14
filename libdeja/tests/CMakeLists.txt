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

vala_precompile(VALA_C runner.vala
                PACKAGES gio-2.0 libpeas-1.0 libsecret-1 posix
                CUSTOM_VAPIS ${CMAKE_BINARY_DIR}/libdeja/deja.vapi
                             ${CMAKE_SOURCE_DIR}/vapi/config.vapi
                OPTIONS ${COMMON_VFLAGS})
add_executable(test-runner ${VALA_C})
target_link_libraries(test-runner deja ${GLIB_LDFLAGS} ${PEAS_LDFLAGS} ${SECRET_LDFLAGS})
set_target_properties(test-runner PROPERTIES
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${PEAS_CFLAGS} ${SECRET_CFLAGS} ${COMMON_CFLAGS}"
                      INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/libdeja")

file(GLOB SCRIPTS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/scripts scripts/*.test)
foreach(SCRIPT ${SCRIPTS})
  add_test(${SCRIPT} env top_builddir=${CMAKE_BINARY_DIR} srcdir=${CMAKE_CURRENT_SOURCE_DIR} dbus-launch ./test-runner ${CMAKE_CURRENT_SOURCE_DIR}/scripts/${SCRIPT})
endforeach()

# Now add some dependencies for the special test-system target
foreach(SCRIPT ${SCRIPTS})
  add_custom_target(test-system-${SCRIPT}
                    COMMAND env top_builddir=${CMAKE_BINARY_DIR} srcdir=${CMAKE_CURRENT_SOURCE_DIR} dbus-launch ./test-runner --system ${CMAKE_CURRENT_SOURCE_DIR}/scripts/${SCRIPT})
  set(TEST_SYSTEM_TARGETS ${TEST_SYSTEM_TARGETS} test-system-${SCRIPT})
endforeach()
add_dependencies(test-system test-runner ${TEST_SYSTEM_TARGETS})

endif(BUILD_TESTING)

add_subdirectory(unit)
