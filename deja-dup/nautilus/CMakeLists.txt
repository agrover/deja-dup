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

if(ENABLE_NAUTILUS)
add_library(deja-dup-nautilus MODULE NautilusExtension.c)
target_link_libraries(deja-dup-nautilus ${GLIB_LDFLAGS} ${NAUTILUS_LDFLAGS})
set_target_properties(deja-dup-nautilus PROPERTIES
                      OUTPUT_NAME deja-dup
                      INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/libdeja"
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${NAUTILUS_CFLAGS} ${COMMON_CFLAGS}")
install(TARGETS deja-dup-nautilus DESTINATION "${NAUTILUS_EXTENSIONDIR}")
endif()
