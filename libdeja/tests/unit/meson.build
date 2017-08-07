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

unit_tests = executable('unit-tests', ['unit-tests.vala'],
    vala_args: common_vflags,
    c_args: common_cflags,
    dependencies: [gio_dep, goa_dep, peas_dep, secret_dep],
    link_with: [libdeja],
    include_directories: [libdeja_inc])

test('unit-tests', dbus_run_session,
    env: ['top_builddir=' + meson.build_root(),
          'top_srcdir=' + meson.source_root(),
          'srcdir=' + meson.current_source_dir()],
    args: [unit_tests.full_path()])

# The network test is manual for the moment
network_test = executable('network-test', ['network.vala'],
    vala_args: common_vflags,
    c_args: common_cflags,
    dependencies: [gio_dep, goa_dep, peas_dep, secret_dep],
    link_with: [libdeja],
    include_directories: [libdeja_inc])
