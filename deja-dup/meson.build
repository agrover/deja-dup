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

subdir('widgets')

deja_dup = executable('deja-dup',
    ['main.vala',
     'Assistant.vala',
     'AssistantBackup.vala',
     'AssistantOperation.vala',
     'AssistantRestore.vala',
     'AssistantRestoreMissing.vala',
     'MountOperationAssistant.vala',
     'Prompt.vala',
     'StatusIcon.vala'],
    vala_args: common_vflags,
    c_args: common_cflags,
    dependencies: [gio_unix_dep, gtk_dep, notify_dep, peas_dep, secret_dep],
    link_with: [libdeja, libwidgets],
    include_directories: [libdeja_inc, libwidgets_inc],
    install: true)

deja_dup_desktop = custom_target('deja-dup.desktop',
    input: 'deja-dup.desktop.in',
    output: 'deja-dup.desktop',
    # List keywords due to https://savannah.gnu.org/support/?108887
    command: [msgfmt, '--desktop', '--keyword=Name', '--keyword=Comment', '--keyword=Keywords', '--template', '@INPUT@', '-d', podir, '-o', '@OUTPUT@'],
    install: true,
    install_dir: join_paths(datadir, 'applications'))

test('validate-deja-dup.desktop', desktop_file_validate,
    args: [deja_dup_desktop.full_path()])

deja_dup_appdata = custom_target('deja-dup.appdata.xml',
    input: 'deja-dup.appdata.xml.in',
    output: 'deja-dup.appdata.xml',
    command: [msgfmt, '--xml', '--template', '@INPUT@', '-d', podir, '-o', '@OUTPUT@'],
    install: true,
    install_dir: join_paths(datadir, 'appdata'))

test('validate-appstream', appstream_util,
    args: ['--nonet', 'validate-relax', deja_dup_appdata.full_path()])

install_subdir('ui', install_dir: pkgdatadir)

subdir('help')
subdir('monitor')
subdir('nautilus')
subdir('preferences')
subdir('tests')
