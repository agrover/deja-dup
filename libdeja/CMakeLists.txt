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

vala_precompile(VALA_C AsyncCommand.vala
                       Backend.vala
                       BackendAuto.vala
                       BackendFile.vala
                       BackendGCS.vala
                       BackendGDrive.vala
                       BackendRackspace.vala
                       BackendS3.vala
                       BackendU1.vala
                       Checker.vala
                       CommonUtils.vala
                       DirHandling.vala
                       FilteredSettings.vala
                       Network.vala
                       Operation.vala
                       OperationBackup.vala
                       OperationFiles.vala
                       OperationRestore.vala
                       OperationStatus.vala
                       OperationVerify.vala
                       PythonChecker.vala
                       RecursiveDelete.vala
                       RecursiveMove.vala
                       RecursiveOp.vala
                       ToolPlugin.vala
                PACKAGES gio-2.0 gio-unix-2.0 libpeas-1.0 libsecret-1 posix
                CUSTOM_VAPIS ${CMAKE_SOURCE_DIR}/vapi/config.vapi
                             ${CMAKE_SOURCE_DIR}/vapi/secret.vapi
                             ${CMAKE_SOURCE_DIR}/vapi/uriutils.vapi
                OPTIONS ${COMMON_VFLAGS}
                GENERATE_VAPI deja
                GENERATE_HEADER deja)
add_library(deja SHARED ${VALA_C} uriutils.c)
target_link_libraries(deja ${GLIB_LDFLAGS} ${PEAS_LDFLAGS} ${SECRET_LDFLAGS})
set_target_properties(deja PROPERTIES
                      INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}"
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${PEAS_CFLAGS} ${SECRET_CFLAGS} ${COMMON_CFLAGS}")
install(TARGETS deja DESTINATION "${PKG_LIBDIR}")

add_subdirectory(tests)
add_subdirectory(tools)
