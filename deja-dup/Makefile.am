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

bin_PROGRAMS = deja-dup

deja_dup_CFLAGS = \
	-I$(top_srcdir)/common \
	-I$(top_srcdir)/widgets \
	$(DUP_CFLAGS) \
	$(UNITY_CFLAGS) \
	-w \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

deja_dup_LDADD = \
	$(DUP_LIBS) \
	$(UNITY_LIBS) \
	@INTLLIBS@ \
	$(top_builddir)/common/libcommon.la \
	$(top_builddir)/widgets/libwidgets.la

deja_dup_VALASOURCES = \
	Assistant.vala \
	AssistantBackup.vala \
	AssistantOperation.vala \
	AssistantRestore.vala \
	AssistantRestoreMissing.vala \
	MountOperationAssistant.vala \
	Prompt.vala \
	StatusIcon.vala \
	main.vala

deja_dup_SOURCES = \
	$(deja_dup_VALASOURCES)

AM_VALAFLAGS = \
	--vapidir $(top_srcdir)/common \
	--vapidir $(top_srcdir)/widgets \
	--vapidir $(top_srcdir)/vapi \
	$(SHARED_VALAFLAGS) \
	$(UNITY_VALAFLAGS) \
	--pkg @GTK_MODULE@ \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	--pkg gnome-keyring-1 \
	--pkg libpeas-1.0 \
	--pkg libnotify \
	--pkg libcommon \
	--pkg libwidgets \
	--pkg keyring \
	--pkg config

deja_dup_vala.stamp: $(top_srcdir)/config.h

dist-hook:
	cd $(distdir) && rm $(deja_dup_VALASOURCES:.vala=.c) \
	                    deja_dup_vala.stamp

CLEANFILES = deja_dup_vala.stamp
