# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# © 2008,2009 Michael Terry <mike@mterry.name>,
# © 2009 Andrew Fister <temposs@gmail.com>
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

bin_PROGRAMS = deja-dup-monitor

VALA_CFLAGS = \
	--vapidir $(top_srcdir)/libdeja-dup \
	--vapidir $(top_srcdir)/vapi \
	--pkg gtk+-2.0 \
	--pkg gconf-2.0 \
	--pkg libdeja-dup \
	--pkg config \
	--pkg dbus-glib-1

AM_CFLAGS = \
	-I$(top_srcdir)/libdeja-dup \
	$(MONITOR_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

deja_dup_monitor_VALASOURCES = \
	monitor.vala

BUILT_SOURCES = \
	vala.stamp

deja_dup_monitor_SOURCES = \
	$(deja_dup_monitor_VALASOURCES:.vala=.c)

vala.stamp: $(deja_dup_monitor_VALASOURCES)
if USE_VALAC
	$(AM_V_GEN)$(VALAC) -C $(VALA_CFLAGS) $^
	@touch $@
else
	@echo "ERROR: Valac compilation is disabled, but the C sources are out-of-date."
	@exit 1
endif

deja_dup_monitor_LDADD = $(MONITOR_LIBS) @INTLLIBS@ $(top_builddir)/libdeja-dup/libdeja-dup.la

EXTRA_DIST = vala.stamp $(deja_dup_monitor_VALASOURCES)
