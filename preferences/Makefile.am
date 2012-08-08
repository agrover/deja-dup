# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-
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

if HAVE_CCPANEL
ccpaneldir = $(CCPANEL_DIR)
ccpanel_LTLIBRARIES = libdeja-dup.la
endif

bin_PROGRAMS = deja-dup-preferences

SHARED_CFLAGS = \
	-I$(top_srcdir)/common \
	-I$(top_srcdir)/widgets \
	$(PREF_CFLAGS) \
	-w \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"
libdeja_dup_la_CFLAGS = \
	$(SHARED_CFLAGS) \
	$(CCPANEL_CFLAGS)
deja_dup_preferences_CFLAGS = \
	$(SHARED_CFLAGS)

SHARED_LIBS = \
	$(PREF_LIBS) \
	@INTLLIBS@ \
	$(top_builddir)/common/libcommon.la \
	$(top_builddir)/widgets/libwidgets.la
libdeja_dup_la_LDFLAGS = -module -avoid-version
libdeja_dup_la_LIBADD = \
	$(SHARED_LIBS) \
	$(CCPANEL_LIBS)
deja_dup_preferences_LDADD = \
	$(SHARED_LIBS)

libdeja_dup_la_VALASOURCES = \
	Preferences.vala

libdeja_dup_la_SOURCES = \
	$(libdeja_dup_la_VALASOURCES) \
	PreferencesPanel.c

deja_dup_preferences_VALASOURCES = \
	Preferences.vala \
	preferences-main.vala

deja_dup_preferences_SOURCES = \
	$(deja_dup_preferences_VALASOURCES)

AM_VALAFLAGS = \
	--vapidir $(top_srcdir)/common \
	--vapidir $(top_srcdir)/widgets \
	--vapidir $(top_srcdir)/vapi \
	$(SHARED_VALAFLAGS) \
	--pkg @GTK_MODULE@ \
	--pkg gio-2.0 \
	--pkg libpeas-1.0 \
	--pkg libcommon \
	--pkg libwidgets \
	--pkg config

libdeja_dup_la_vala.stamp: $(top_srcdir)/config.h
deja_dup_preferences_vala.stamp: $(top_srcdir)/config.h

dist-hook:
	cd $(distdir) && rm $(shell echo $(libdeja_dup_la_VALASOURCES:.vala=.c) \
	                                 $(deja_dup_preferences_VALASOURCES:.vala=.c) | tr ' ' '\n' | sort | uniq) \
	                    libdeja_dup_la_vala.stamp deja_dup_preferences_vala.stamp

CLEANFILES = libdeja_dup_la_vala.stamp deja_dup_preferences_vala.stamp
