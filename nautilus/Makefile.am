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

if HAVE_NAUTILUS
nautilusdir = $(NAUTILUS_EXTENSION_DIR)

nautilus_LTLIBRARIES = libnautilus-deja-dup.la

AM_CFLAGS = \
	$(NAUTILUS_CFLAGS) \
	$(DEBUG_CFLAGS)

libnautilus_deja_dup_la_SOURCES = \
	NautilusExtension.c NautilusExtension.h

libnautilus_deja_dup_la_LDFLAGS = -module -avoid-version
libnautilus_deja_dup_la_LIBADD = $(NAUTILUS_LIBS) @INTLLIBS@
endif
