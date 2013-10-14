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

vala_precompile(VALA_C ConfigBool.vala
                       ConfigChoice.vala
                       ConfigDelete.vala
                       ConfigEntry.vala
                       ConfigFolder.vala
                       ConfigLabel.vala
                       ConfigLabelBackupDate.vala
                       ConfigLabelBool.vala
                       ConfigLabelList.vala
                       ConfigLabelLocation.vala
                       ConfigLabelPolicy.vala
                       ConfigList.vala
                       ConfigLocation.vala
                       ConfigLocationCustom.vala
                       ConfigLocationDAV.vala
                       ConfigLocationFile.vala
                       ConfigLocationFTP.vala
                       ConfigLocationRackspace.vala
                       ConfigLocationS3.vala
                       ConfigLocationSSH.vala
                       ConfigLocationSMB.vala
                       ConfigLocationTable.vala
                       ConfigLocationU1.vala
                       ConfigLocationVolume.vala
                       ConfigNumber.vala
                       ConfigPeriod.vala
                       ConfigRelPath.vala
                       ConfigURLPart.vala
                       ConfigURLPartBool.vala
                       ConfigWidget.vala
                       WidgetUtils.vala
                PACKAGES gtk+-3.0 libnotify libpeas-1.0 libsecret-1
                CUSTOM_VAPIS ${CMAKE_BINARY_DIR}/libdeja/deja.vapi
                             ${CMAKE_SOURCE_DIR}/vapi/config.vapi
                             ${CMAKE_SOURCE_DIR}/vapi/uriutils.vapi
                OPTIONS ${COMMON_VFLAGS}
                GENERATE_VAPI widgets
                GENERATE_HEADER widgets)
add_library(widgets SHARED ${VALA_C})
target_link_libraries(widgets deja "${GTK_LDFLAGS} ${NOTIFY_LDFLAGS} ${PEAS_LDFLAGS} ${SECRET_LDFLAGS}")
set_target_properties(widgets PROPERTIES
                      INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/libdeja;${CMAKE_SOURCE_DIR}/libdeja"
                      COMPILE_FLAGS "${GTK_CFLAGS} ${NOTIFY_CFLAGS} ${PEAS_CFLAGS} ${SECRET_CFLAGS} ${COMMON_CFLAGS}")
install(TARGETS widgets DESTINATION "${PKG_LIBDIR}")
