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

bin_PROGRAMS = deja-dup

deja_dup_CFLAGS = \
	-I$(top_srcdir)/common \
	-I$(top_srcdir)/widgets \
	$(DUP_CFLAGS) \
	$(APPINDICATOR_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

deja_dup_LDADD = $(DUP_LIBS) $(APPINDICATOR_LIBS) $(UNITY_LIBS) @INTLLIBS@ $(top_builddir)/common/libcommon.la $(top_builddir)/widgets/libwidgets.la

deja_dup_VALASOURCES = \
	Assistant.vala \
	AssistantBackup.vala \
	AssistantOperation.vala \
	AssistantRestore.vala \
	AssistantRestoreMissing.vala \
	MainWindow.vala \
	MountOperationAssistant.vala \
	StatusIcon.vala \
	main.vala

deja_dup_VALABUILTSOURCES = \
	$(deja_dup_VALASOURCES:.vala=.c)

deja_dup_SOURCES = \
	$(deja_dup_VALABUILTSOURCES)

if MAINTAINER_MODE
PACKAGES = \
	--pkg gmodule-2.0 \
	--pkg @GTK_MODULE@ \
	--pkg @GDK_X11_MODULE@ \
	--pkg gio-2.0 \
	--pkg gnome-keyring-1 \
	--pkg libnotify \
	--pkg libcommon \
	--pkg libwidgets \
	--pkg unix \
	--pkg keyring \
	--pkg hacks \
	--pkg hacks-unity \
	--pkg config
BUILT_SOURCES = vala.stamp
vala.stamp: $(deja_dup_VALASOURCES)
	$(AM_V_GEN)$(VALAC) --vapidir $(top_srcdir)/common --vapidir $(top_srcdir)/widgets \
	         --vapidir $(top_srcdir)/vapi $(PACKAGES) $^ -C
	touch $@
endif

EXTRA_DIST = $(deja_dup_VALASOURCES)
if MAINTAINER_MODE
CLEANFILES = $(BUILT_SOURCES) $(deja_dup_VALABUILTSOURCES)
endif
