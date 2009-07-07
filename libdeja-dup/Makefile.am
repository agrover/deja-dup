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

noinst_LTLIBRARIES = libdeja-dup.la

VALA_CFLAGS = \
	--library=libdeja-dup \
	--vapidir $(top_srcdir)/vapi \
	--pkg gtk+-2.0 \
	--pkg gio-2.0 \
	--pkg gconf-2.0 \
	--pkg libgnomeui-2.0 \
	--pkg libnotify \
	--pkg gnome-keyring-1 \
	--pkg dbus-glib-1 \
	--pkg gdk-x11-2.0 \
	--pkg unique-1.0 \
	--pkg posix \
	--pkg hacks \
	--pkg PassphraseSchema \
	--pkg unix \
	--pkg config

AM_CFLAGS = \
	$(LIBRARY_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

libdeja_dup_la_VALASOURCES = \
	Backend.vala \
	BackendFile.vala \
	BackendS3.vala \
	ButtonConnect.vala \
	ConfigBool.vala \
	ConfigChoice.vala \
	ConfigDelete.vala \
	ConfigEntry.vala \
	ConfigLabel.vala \
	ConfigLabelBool.vala \
	ConfigLabelList.vala \
	ConfigLabelLocation.vala \
	ConfigList.vala \
	ConfigLocation.vala \
	ConfigNumber.vala \
	ConfigPeriod.vala \
	ConfigWidget.vala \
	Duplicity.vala \
	DuplicityInfo.vala \
	DuplicityInstance.vala \
	Operation.vala \
	OperationBackup.vala \
	OperationRestore.vala \
	OperationStatus.vala \
	RecursiveDelete.vala \
	RecursiveMove.vala \
	RecursiveOp.vala \
	ToggleGroup.vala \
	libdeja-dup.vala

BUILT_SOURCES = \
	vala.stamp

libdeja_dup_la_SOURCES = \
	hacks.c hacks.h \
	PassphraseSchema.c PassphraseSchema.h \
	deja-dup.h \
	$(libdeja_dup_la_VALASOURCES:.vala=.c) \
	$(libdeja_dup_la_VALASOURCES)

vala.stamp: $(libdeja_dup_la_VALASOURCES)
if USE_VALAC
	$(VALAC) -C -H deja-dup.h $(VALA_CFLAGS) $^
	touch $@
else
	@echo "ERROR: Valac compilation is disabled, but the C sources are out-of-date."
	@exit 1
endif

libdeja_dup_la_LIBADD = $(LIBRARY_LIBS) @INTLLIBS@

EXTRA_DIST = vala.stamp
DISTCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libdeja_dup_la_VALASOURCES:.vala=.c) \
	$(libdeja_dup_la_VALASOURCES:.vala=.h)

