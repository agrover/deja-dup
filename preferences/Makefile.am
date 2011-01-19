# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# © 2008–2010 Michael Terry <mike@mterry.name>
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

bin_PROGRAMS = deja-dup-preferences

deja_dup_preferences_CFLAGS = \
	-I$(top_srcdir)/common \
	-I$(top_srcdir)/widgets \
	$(PREF_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

deja_dup_preferences_LDADD = $(PREF_LIBS) @INTLLIBS@ $(top_builddir)/common/libcommon.la $(top_builddir)/widgets/libwidgets.la

deja_dup_preferences_VALASOURCES = \
	PreferencesDialog.vala \
	preferences.vala

deja_dup_preferences_VALABUILTSOURCES = \
	$(deja_dup_preferences_VALASOURCES:.vala=.c)

deja_dup_preferences_SOURCES = \
	$(deja_dup_preferences_VALABUILTSOURCES)

if MAINTAINER_MODE
PACKAGES = \
	--pkg @GTK_MODULE@ \
	--pkg @UNIQUE_MODULE@ \
	--pkg gio-2.0 \
	--pkg libcommon \
	--pkg libwidgets \
	--pkg hacks \
	--pkg unix \
	--pkg config
BUILT_SOURCES = vala.stamp
vala.stamp: $(deja_dup_preferences_VALASOURCES)
	$(AM_V_GEN)$(VALAC) --vapidir $(top_srcdir)/common --vapidir $(top_srcdir)/widgets \
	                    --vapidir $(top_srcdir)/vapi $(PACKAGES) $^ -C
	touch $@
endif

EXTRA_DIST = $(deja_dup_preferences_VALASOURCES)
if MAINTAINER_MODE
CLEANFILES = $(BUILT_SOURCES) $(deja_dup_preferences_VALABUILTSOURCES)
endif
