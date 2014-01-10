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

project(deja-dup C)
set(SERIES 30)
set(VERSION 29.1)
cmake_minimum_required(VERSION 2.8)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
include(DejaDupMacros)

deja_option(ENABLE_CCPANEL "Build gnome-control-center panel" CHECK)
deja_option(ENABLE_NAUTILUS "Build nautilus plugin" CHECK)
deja_option(ENABLE_UNITY "Integrate with Unity" CHECK)
deja_option(ENABLE_UNITY_CCPANEL "Build unity-control-center panel" CHECK)

find_package(PkgConfig 0.24 REQUIRED)
find_package(Vala 0.20 REQUIRED)
deja_find_required_program(MSGFMT msgfmt)
deja_find_required_program(INTLTOOL_MERGE intltool-merge)
deja_check_modules(GLIB REQUIRED glib-2.0>=2.34 gio-2.0 gio-unix-2.0 gmodule-2.0)
deja_check_modules(GTK REQUIRED gtk+-3.0>=3.6)
deja_check_modules(NOTIFY REQUIRED libnotify>=0.7)
deja_check_modules(PEAS REQUIRED libpeas-1.0)
deja_check_modules(SECRET REQUIRED libsecret-1)

deja_enable_option(CCPANEL libgnome-control-center>=3.4)
if(ENABLE_CCPANEL)
  execute_process(COMMAND ${PKG_CONFIG_EXECUTABLE} --variable=extensiondir libgnome-control-center
                  OUTPUT_VARIABLE CCPANEL_EXTENSIONDIR
                  OUTPUT_STRIP_TRAILING_WHITESPACE
                  ERROR_QUIET)
endif()

deja_enable_option(NAUTILUS libnautilus-extension)
if(ENABLE_NAUTILUS)
  execute_process(COMMAND ${PKG_CONFIG_EXECUTABLE} --variable=extensiondir libnautilus-extension
                  OUTPUT_VARIABLE NAUTILUS_EXTENSIONDIR
                  OUTPUT_STRIP_TRAILING_WHITESPACE
                  ERROR_QUIET)
endif()

deja_enable_option(UNITY unity>=3.4.2)

deja_enable_option(UNITY_CCPANEL libunity-control-center)
if(ENABLE_UNITY_CCPANEL)
  execute_process(COMMAND ${PKG_CONFIG_EXECUTABLE} --variable=extensiondir libunity-control-center
                  OUTPUT_VARIABLE UNITY_CCPANEL_EXTENSIONDIR
                  OUTPUT_STRIP_TRAILING_WHITESPACE
                  ERROR_QUIET)
endif()

# Set up some common configuration values; Vala sees these via config.vapi.
include(GNUInstallDirs)
set(PACKAGE "deja-dup")
set(GETTEXT_PACKAGE "deja-dup")
set(PKG_DATADIR "${CMAKE_INSTALL_FULL_DATADIR}/${PACKAGE}")
set(PKG_LIBDIR "${CMAKE_INSTALL_FULL_LIBDIR}/${PACKAGE}")
set(PKG_LIBEXECDIR "${CMAKE_INSTALL_FULL_LIBEXECDIR}/${PACKAGE}")
set(CMAKE_INSTALL_RPATH "${PKG_LIBDIR}") # internal libraries go here
set(COMMON_CFLAGS "-w")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DPACKAGE=\\\"${PACKAGE}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DGETTEXT_PACKAGE=\\\"${GETTEXT_PACKAGE}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DVERSION=\\\"${VERSION}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLOCALE_DIR=\\\"${CMAKE_INSTALL_FULL_LOCALEDIR}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DTHEME_DIR=\\\"${CMAKE_INSTALL_FULL_DATADIR}/icons\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DPKG_DATA_DIR=\\\"${PKG_DATADIR}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DPKG_LIBEXEC_DIR=\\\"${PKG_LIBEXECDIR}\\\"")

include(${VALA_USE_FILE})
set(COMMON_VFLAGS --target-glib=2.34)
if(GTK_VERSION VERSION_GREATER "3.10" OR GTK_VERSION VERSION_EQUAL "3.10")
  set(COMMON_VFLAGS ${COMMON_VFLAGS} -D HAVE_GTK_3_10)
endif()

include(CTest)
enable_testing()
add_custom_target(autopilot)
add_custom_target(autopilot-system)
add_custom_target(test-system)

set(CPACK_PACKAGE_VERSION "${VERSION}")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "${PACKAGE}-${VERSION}")
set(CPACK_SOURCE_GENERATOR "TBZ2")
SET(CPACK_SOURCE_IGNORE_FILES "/.bzr/;/.bzrignore;/builddir/;/debian/;~$")
include(CPack)

add_subdirectory(data)
add_subdirectory(deja-dup)
add_subdirectory(libdeja)
add_subdirectory(man)
add_subdirectory(po)
add_subdirectory(tests)
