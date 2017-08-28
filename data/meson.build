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

install_subdir(join_paths('icons', 'hicolor'),
    install_dir: join_paths(datadir, 'icons'))

install_data('deja-dup.convert',
    install_dir: join_paths(datadir, 'GConf', 'gsettings'))

install_man('deja-dup.1')

install_data('org.gnome.DejaDup.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'))

test('validate-gschema', glib_compile_schemas,
    args: ['--strict', '--dry-run', '--schema-file',
           join_paths(meson.current_source_dir(), 'org.gnome.DejaDup.gschema.xml')])

conf_data = configuration_data()
conf_data.set('bindir', bindir)
configure_file(input: 'org.gnome.DejaDup.service.in',
    output: 'org.gnome.DejaDup.service',
    configuration: conf_data,
    install_dir: join_paths(datadir, 'dbus-1', 'services'))

conf_data = configuration_data()
conf_data.set('pkglibexecdir', pkglibexecdir)
monitor_desktop = configure_file(input: 'org.gnome.DejaDup.Monitor.desktop.in',
    output: 'org.gnome.DejaDup.Monitor.desktop',
    configuration: conf_data,
    install_dir: join_paths(etcdir, 'xdg', 'autostart'))

test('validate-monitor-desktop', desktop_file_validate,
    args: [monitor_desktop])

deja_dup_desktop = custom_target('org.gnome.DejaDup.desktop',
    input: 'org.gnome.DejaDup.desktop',
    output: 'org.gnome.DejaDup.desktop',
    # List keywords due to https://savannah.gnu.org/support/?108887
    command: [msgfmt, '--desktop', '--keyword=Name', '--keyword=Comment', '--keyword=Keywords', '--template', '@INPUT@', '-d', podir, '-o', '@OUTPUT@'],
    install: true,
    install_dir: join_paths(datadir, 'applications'))

test('validate-desktop', desktop_file_validate,
    args: [deja_dup_desktop.full_path()])

conf_data = configuration_data()
conf_data.set('series', series)
conf_data.set('version', meson.project_version())
vars = configure_file(input: 'org.gnome.DejaDup.appdata.xml.in',
    output: 'org.gnome.DejaDup.vars.appdata.xml.in',
    configuration: conf_data)
deja_dup_appdata = custom_target('org.gnome.DejaDup.appdata.xml',
    input: vars,
    output: 'org.gnome.DejaDup.appdata.xml',
    command: [msgfmt, '--xml', '--template', '@INPUT@', '-d', podir, '-o', '@OUTPUT@'],
    install: true,
    install_dir: join_paths(datadir, 'metainfo'))

test('validate-appstream', appstream_util,
    args: ['--nonet', 'validate-relax', deja_dup_appdata.full_path()])

conf_data = configuration_data()
conf_data.set('pkglibexecdir', pkglibexecdir)
configure_file(input: 'org.gnome.DejaDup.policy.in',
    output: 'org.gnome.DejaDup.policy',
    configuration: conf_data,
    install_dir: join_paths(datadir, 'polkit-1', 'actions'))

resources = gnome.compile_resources('resources', 'resources.xml',
    source_dir: ['ui'])

message('You may need to recompile your gsettings schemas or regenerate
         your icon cache after installation.')
