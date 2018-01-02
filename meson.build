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

project('deja-dup', ['vala', 'c'],
    version: '37.1',
    license: 'GPLv3+',
    default_options: [
        'warning_level=1',
        'buildtype=debugoptimized',
    ],
    meson_version: '>= 0.38')
series = '38'

gnome = import('gnome')
i18n = import('i18n')
 
# Source paths
podir = join_paths(meson.current_source_dir(), 'po')
vapidir = join_paths(meson.current_source_dir(), 'vapi')

# Install paths
prefix = get_option('prefix')
bindir = join_paths(prefix, get_option('bindir'))
datadir = join_paths(prefix, get_option('datadir'))
etcdir = get_option('sysconfdir')
libdir = join_paths(prefix, get_option('libdir'))
libexecdir = join_paths(prefix, get_option('libexecdir'))
localedir = join_paths(prefix, get_option('localedir'))
pkgdatadir = join_paths(datadir, meson.project_name())
pkglibdir = join_paths(libdir, meson.project_name())
pkglibexecdir = join_paths(libexecdir, meson.project_name())
toolsdir = join_paths(pkglibexecdir, 'tools')

# Dependencies
gio_dep = dependency('gio-2.0', version: '>= 2.46')
gio_unix_dep = dependency('gio-unix-2.0')
goa_dep = dependency('goa-1.0', version: '>= 3.8.0')
goabackend_dep = dependency('goa-backend-1.0')
gtk_dep = dependency('gtk+-3.0', version: '>= 3.22')
nautilus_dep = dependency('libnautilus-extension', required: false)
packagekit_dep = dependency('packagekit-glib2', version: '>=0.6.5', required: false)
peas_dep = dependency('libpeas-1.0')
secret_dep = dependency('libsecret-1')

# libgpg-error doesn't ship a pkg-config file
gpgerror_libs = run_command('gpg-error-config', '--libs').stdout().strip()
gpgerror_dep = declare_dependency(link_args: gpgerror_libs)

# Programs
appstream_util = find_program('appstream-util')
dbus_run_session = find_program('dbus-run-session')
desktop_file_validate = find_program('desktop-file-validate')
glib_compile_schemas = find_program('glib-compile-schemas')
msgfmt = find_program('msgfmt')

common_vflags = [
    '--pkg=config',
    '--pkg=posix',
    '--target-glib=2.46',
    '--vapidir', vapidir]
common_cflags = [
    '-w',
    '-DGOA_API_IS_SUBJECT_TO_CHANGE',
    '-DGOA_BACKEND_API_IS_SUBJECT_TO_CHANGE',
    '-DI_KNOW_THE_PACKAGEKIT_GLIB2_API_IS_SUBJECT_TO_CHANGE',
    '-DDUPLICITY_PACKAGES="@0@"'.format(get_option('duplicity_pkgs')),
    '-DGVFS_PACKAGES="@0@"'.format(get_option('gvfs_pkgs')),
    '-DBOTO_PACKAGES="@0@"'.format(get_option('boto_pkgs')),
    '-DCLOUDFILES_PACKAGES="@0@"'.format(get_option('cloudfiles_pkgs')),
    '-DSWIFTCLIENT_PACKAGES="@0@"'.format(get_option('swiftclient_pkgs')),
    '-DPACKAGE="@0@"'.format(meson.project_name()),
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DVERSION="@0@"'.format(meson.project_version()),
    '-DLOCALE_DIR="@0@"'.format(localedir),
    '-DTHEME_DIR="@0@"'.format(join_paths(datadir, 'icons')),
    '-DPKG_LIBEXEC_DIR="@0@"'.format(pkglibexecdir)]

if packagekit_dep.found()
common_vflags += ['--define=HAS_PACKAGEKIT']
endif

subdir('data')
subdir('libdeja')
subdir('deja-dup')
subdir('po')
