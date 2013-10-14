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

vala_precompile(VALA_C main.vala
                       Assistant.vala
                       AssistantBackup.vala
                       AssistantOperation.vala
                       AssistantRestore.vala
                       AssistantRestoreMissing.vala
                       MountOperationAssistant.vala
                       Prompt.vala
                       StatusIcon.vala
                PACKAGES gio-unix-2.0 gtk+-3.0 libnotify libpeas-1.0 libsecret-1
                CUSTOM_VAPIS ${CMAKE_BINARY_DIR}/libdeja/deja.vapi
                             ${CMAKE_CURRENT_BINARY_DIR}/widgets/widgets.vapi
                             ${CMAKE_SOURCE_DIR}/vapi/config.vapi
                OPTIONS ${COMMON_VFLAGS})
add_executable(deja-dup ${VALA_C})
target_link_libraries(deja-dup deja widgets ${GTK_LDFLAGS} ${NOTIFY_LDFLAGS} ${PEAS_LDFLAGS} ${SECRET_LDFLAGS})
set_target_properties(deja-dup PROPERTIES
                      COMPILE_FLAGS "${GTK_CFLAGS} ${NOTIFY_CFLAGS} ${PEAS_CFLAGS} ${SECRET_CFLAGS} ${COMMON_CFLAGS}"
                      INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/libdeja;${CMAKE_CURRENT_BINARY_DIR}/widgets")
install(TARGETS deja-dup DESTINATION bin)

deja_merge_po(desktop deja-dup.desktop "${CMAKE_INSTALL_FULL_DATADIR}/applications")

deja_merge_po(xml deja-dup.appdata.xml "${CMAKE_INSTALL_FULL_DATADIR}/appdata")
find_program(APPDATA_VALIDATE appdata-validate)
if(APPDATA_VALIDATE)
  add_test(validate-deja-dup.appdata.xml appdata-validate --relax "${CMAKE_CURRENT_BINARY_DIR}/deja-dup.appdata.xml")
endif()

install(DIRECTORY ui DESTINATION "${PKG_DATADIR}")

add_subdirectory(help)
add_subdirectory(monitor)
add_subdirectory(nautilus)
add_subdirectory(preferences)
add_subdirectory(tests)
add_subdirectory(widgets)
