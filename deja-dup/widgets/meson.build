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

libwidgets = shared_library('widgets',
    ['ConfigBool.vala',
     'ConfigChoice.vala',
     'ConfigDelete.vala',
     'ConfigEntry.vala',
     'ConfigFolder.vala',
     'ConfigLabel.vala',
     'ConfigLabelBackupDate.vala',
     'ConfigLabelDescription.vala',
     'ConfigLabelLocation.vala',
     'ConfigList.vala',
     'ConfigLocation.vala',
     'ConfigLocationCustom.vala',
     'ConfigLocationFile.vala',
     'ConfigLocationGCS.vala',
     'ConfigLocationGoa.vala',
     'ConfigLocationOpenstack.vala',
     'ConfigLocationRackspace.vala',
     'ConfigLocationS3.vala',
     'ConfigLocationTable.vala',
     'ConfigLocationU1.vala',
     'ConfigLocationVolume.vala',
     'ConfigPeriod.vala',
     'ConfigWidget.vala',
     'WidgetUtils.vala'],
    vala_args: common_vflags + ['--pkg=uriutils'],
    c_args: common_cflags,
    dependencies: [goa_dep, goabackend_dep, gtk_dep, peas_dep, secret_dep],
    link_with: [libdeja],
    include_directories: [libdeja_inc],
    install: true,
    install_dir: pkglibdir)

libwidgets_inc = include_directories('.')
