# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# © 2008,2009 Michael Terry <mike@mterry.name>
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

SUBDIRS = data po vapi common widgets monitor preferences deja-dup nautilus help tests

# Distribute pot file
update-pot:
	$(MAKE) -C po "$(GETTEXT_PACKAGE).pot"
	$(MAKE) -C help update-pot
dist-hook: update-pot

release: distcheck
	gpg --armor --sign --detach-sig deja-dup-$(PACKAGE_VERSION).tar.bz2

ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

DISTCHECK_CONFIGURE_FLAGS = --disable-scrollkeeper

EXTRA_DIST = \
	autogen.sh \
	intltool-extract.in \
	intltool-merge.in \
	intltool-update.in \
	gnome-doc-utils.make

DISTCLEANFILES = \
	intltool-extract \
	intltool-merge \
	intltool-update
