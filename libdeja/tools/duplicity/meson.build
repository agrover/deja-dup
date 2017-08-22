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

shared_module('duplicity',
    ['DuplicityInstance.vala',
     'DuplicityJob.vala',
     'DuplicityPlugin.vala'],
    vala_args: common_vflags,
    c_args: common_cflags,
    dependencies: [gio_dep, gio_unix_dep, goa_dep, gpgerror_dep, peas_dep, secret_dep],
    link_with: [libdeja],
    include_directories: [libdeja_inc],
    install: true,
    install_dir: toolsdir)

# Script tests would like to point at our builddir to use this plugin in-tree.
# So we copy it into builddir with configure_file() and install from there.
configure_file(
    configuration: configuration_data(),
    input: 'duplicity.plugin',
    output: 'duplicity.plugin',
    install_dir: toolsdir)

# This is used when running duplicity as root.
# See data/org.gnome.DejaDup.policy.in and DuplicityInstance.vala for more details.
install_data('duplicity',
    install_dir: pkglibexecdir,
    install_mode: 'rwxr-xr-x')
