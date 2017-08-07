# -*- Mode: Meson; indent-tabs-mode: nil; tab-width: 4 -*-
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

run_target('autopilot',
    command: ['env', 'LANG=C', 'DEJA_DUP_TESTING=1', 'PYTHONDONTWRITEBYTECODE=1', 'PYTHONPATH=' + meson.current_source_dir(), join_paths(meson.source_root(), 'tests', 'shell-local'), 'autopilot-sandbox-run', 'deja_dup_autopilot'],
    depends: [deja_dup])

run_target('autopilot-system',
    command: ['env', 'LANG=C', 'DEJA_DUP_TESTING=1', 'PYTHONDONTWRITEBYTECODE=1', 'PYTHONPATH=' + meson.current_source_dir(), join_paths(meson.source_root(), 'tests', 'shell-system'), 'autopilot-sandbox-run', 'deja_dup_autopilot'])
