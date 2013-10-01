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

execute_process(COMMAND ${PKG_CONFIG_EXECUTABLE} --variable=glib_compile_schemas gio-2.0
                OUTPUT_VARIABLE GLIB_COMPILE_SCHEMAS
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET)
deja_merge_po(xml org.gnome.DejaDup.gschema.xml "${CMAKE_INSTALL_FULL_DATADIR}/glib-2.0/schemas" NO_MERGE)
install(CODE "
  if(\"\$ENV{DESTDIR}\" STREQUAL \"\")
    execute_process(COMMAND ${GLIB_COMPILE_SCHEMAS} \"\$ENV{DESTDIR}${CMAKE_INSTALL_FULL_DATADIR}/glib-2.0/schemas\")
  endif()
")
add_test(validate-org.gnome.DejaDup.gschema.xml ${GLIB_COMPILE_SCHEMAS} --strict --dry-run --schema-file="${CMAKE_CURRENT_BINARY_DIR}/org.gnome.DejaDup.gschema.xml")

install(FILES deja-dup.convert DESTINATION "${CMAKE_INSTALL_FULL_DATADIR}/GConf/gsettings")

install(DIRECTORY icons/hicolor DESTINATION "${CMAKE_INSTALL_FULL_DATADIR}/icons")
find_program(GTK_UPDATE_ICON_CACHE gtk-update-icon-cache)
if(GTK_UPDATE_ICON_CACHE)
install(CODE "
  if(\"\$ENV{DESTDIR}\" STREQUAL \"\")
    execute_process(COMMAND ${GTK_UPDATE_ICON_CACHE} -f -t \"\$ENV{DESTDIR}${CMAKE_INSTALL_FULL_DATADIR}/icons/hicolor\")
  endif()
")
endif()
