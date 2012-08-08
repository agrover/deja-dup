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

pkglibexec_PROGRAMS = deja-dup-monitor

deja_dup_monitor_CFLAGS = \
	-I$(top_srcdir)/common \
	$(MONITOR_CFLAGS) \
	-w \
	-DPKG_LIBEXEC_DIR=\"$(pkglibexecdir)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

deja_dup_monitor_LDADD = \
	$(MONITOR_LIBS) \
	@INTLLIBS@ \
	$(top_builddir)/common/libcommon.la

deja_dup_monitor_VALASOURCES = \
	monitor.vala

deja_dup_monitor_SOURCES = \
	$(deja_dup_monitor_VALASOURCES)

AM_VALAFLAGS = \
	--vapidir $(top_srcdir)/common \
	--vapidir $(top_srcdir)/vapi \
	$(SHARED_VALAFLAGS) \
	--pkg config \
	--pkg gio-2.0 \
	--pkg libpeas-1.0 \
	--pkg libcommon \
	--pkg libnotify

deja_dup_monitor_vala.stamp: $(top_srcdir)/config.h

dist-hook:
	cd $(distdir) && rm $(deja_dup_monitor_VALASOURCES:.vala=.c) \
	                    deja_dup_monitor_vala.stamp

CLEANFILES = deja_dup_monitor_vala.stamp
