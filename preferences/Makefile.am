# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# © 2008,2009,2010,2011 Michael Terry <mike@mterry.name>
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

ccpaneldir = $(CCPANEL_DIR)
ccpanel_LTLIBRARIES = libdeja-dup.la

libdeja_dup_la_CFLAGS = \
	-I$(top_srcdir)/common \
	-I$(top_srcdir)/widgets \
	$(PREF_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

libdeja_dup_la_LIBADD = $(PREF_LIBS) @INTLLIBS@ $(top_builddir)/widgets/libwidgets.la

libdeja_dup_la_VALASOURCES = \
	Preferences.vala

libdeja_dup_la_VALABUILTSOURCES = \
	$(libdeja_dup_la_VALASOURCES:.vala=.c)

libdeja_dup_la_SOURCES = \
	$(libdeja_dup_la_VALABUILTSOURCES) \
	PreferencesPanel.c

if MAINTAINER_MODE
PACKAGES = \
	--pkg @GTK_MODULE@ \
	--pkg gio-2.0 \
	--pkg libcommon \
	--pkg libwidgets \
	--pkg hacks \
	--pkg unix \
	--pkg config
BUILT_SOURCES = vala.stamp
vala.stamp: $(libdeja_dup_la_VALASOURCES)
	$(AM_V_GEN)$(VALAC) --vapidir $(top_srcdir)/common -H preferences.h --vapidir $(top_srcdir)/widgets \
	                    --vapidir $(top_srcdir)/vapi $(PACKAGES) $^ -C
	touch $@
endif

EXTRA_DIST = $(libdeja_dup_la_VALASOURCES)
if MAINTAINER_MODE
CLEANFILES = $(BUILT_SOURCES) $(libdeja_dup_la_VALABUILTSOURCES)
endif
