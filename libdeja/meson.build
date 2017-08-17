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

libdeja = shared_library('deja',
    ['Backend.vala',
     'BackendAuto.vala',
     'BackendDrive.vala',
     'BackendFile.vala',
     'BackendGCS.vala',
     'BackendGOA.vala',
     'BackendLocal.vala',
     'BackendOpenstack.vala',
     'BackendRackspace.vala',
     'BackendRemote.vala',
     'BackendS3.vala',
     'BackendU1.vala',
     'CommonUtils.vala',
     'DirHandling.vala',
     'FilteredSettings.vala',
     'Network.vala',
     'Operation.vala',
     'OperationBackup.vala',
     'OperationFiles.vala',
     'OperationRestore.vala',
     'OperationStatus.vala',
     'OperationVerify.vala',
     'RecursiveDelete.vala',
     'RecursiveMove.vala',
     'RecursiveOp.vala',
     'ToolPlugin.vala',
     'uriutils.c'],
    vala_args: common_vflags + ['--pkg=secret', '--pkg=uriutils'],
    c_args: common_cflags,
    dependencies: [gio_dep, gio_unix_dep, goa_dep, goabackend_dep, packagekit_dep, peas_dep, secret_dep],
    install: true,
    install_dir: pkglibdir)

libdeja_inc = include_directories('.')

subdir('tests')
subdir('tools')
