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

if(ENABLE_CCPANEL)
  set(HAS_CCPANEL "1")
else()
  set(HAS_CCPANEL "0")
endif()

add_custom_target(autopilot-system-deja-dup
                  COMMAND env HAS_CCPANEL=${HAS_CCPANEL} LANG=C DEJA_DUP_TESTING=1 PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_SOURCE_DIR}/tests/shell-system" autopilot run deja_dup_autopilot)
add_dependencies(autopilot-system autopilot-system-deja-dup)

add_custom_target(autopilot-deja-dup
                  COMMAND env HAS_CCPANEL=${HAS_CCPANEL} LANG=C DEJA_DUP_TESTING=1 PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_SOURCE_DIR}/tests/shell" autopilot run deja_dup_autopilot)
add_dependencies(autopilot autopilot-deja-dup)
