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

test_runner = executable('test-runner', ['runner.vala'],
    vala_args: common_vflags,
    c_args: common_cflags,
    dependencies: [gio_dep, goa_dep, peas_dep, secret_dep],
    link_with: [libdeja],
    include_directories: [libdeja_inc])

tests = [
    'as-root',
    'bad-hostname',
    'bad-volume',
    'cancel-noop',
    'cancel',
    'clean-cache-if-full',
    'clean-cache',
    'clean-incomplete',
    'clean-tempdir',
    'delete-just-right',
    'delete-never',
    'delete-too-few',
    'delete-too-old',
    'disk-full2',
    'disk-full',
    'disk-small',
    'encrypt-ask',
    'encrypt-detect',
    'excludes',
    'instance-error',
    'mkdir',
    'nag',
    'no-space',
    'old-version',
    'permission',
    'read-error',
    'rename-one',
    'rename-two',
    'restore-date',
    'restore-specific',
    'special-chars',
    'stop',
    'symlink-direct',
    'symlink-exclude2',
    'symlink-exclude',
    'symlink-follow2',
    'symlink-follow',
    'symlink-loop',
    'symlink-recursive',
    'symlink-subdir',
    'symlink-trickshot',
    'threshold-full',
    'threshold-inc',
    'u1',
    'verify',
    'write-error'
]

foreach t: tests
    test('script-' + t, dbus_run_session,
        env: ['top_builddir=' + meson.build_root(),
              'top_srcdir=' + meson.source_root(),
              'srcdir=' + meson.current_source_dir()],
        args: [test_runner.full_path(),
               join_paths(meson.current_source_dir(), 'scripts', t + '.test')])
endforeach

subdir('unit')
