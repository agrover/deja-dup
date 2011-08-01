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
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"
libdeja_dup_la_CFLAGS = \
	$(SHARED_CFLAGS) \
	$(CCPANEL_CFLAGS)
deja_dup_preferences_CFLAGS = \
	$(SHARED_CFLAGS)

SHARED_LIBS = \
	$(PREF_LIBS) \
	@INTLLIBS@ \
	$(top_builddir)/widgets/libwidgets.la
libdeja_dup_la_LDFLAGS = -module -avoid-version
libdeja_dup_la_LIBADD = \
	$(SHARED_LIBS) \
	$(CCPANEL_LIBS)
deja_dup_preferences_LDADD = \
	$(SHARED_LIBS)

libdeja_dup_la_SOURCES = \
	Preferences.vala \
	PreferencesPanel.c

deja_dup_preferences_SOURCES = \
	Preferences.vala \
	preferences-main.vala

AM_VALAFLAGS = \
	--vapidir $(top_srcdir)/common \
	--vapidir $(top_srcdir)/widgets \
	--vapidir $(top_srcdir)/vapi \
	--pkg @GTK_MODULE@ \
	--pkg gio-2.0 \
	--pkg libcommon \
	--pkg libwidgets \
	--pkg hacks \
	--pkg unix \
	--pkg config
