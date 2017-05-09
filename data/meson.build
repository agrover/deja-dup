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

message('You may need to recompile your gsettings schemas or regenerate
         your icon cache after installation.')
