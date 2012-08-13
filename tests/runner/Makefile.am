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

check_PROGRAMS = \
	runner

check:
	@set -e; for test in $(srcdir)/../scripts/*.test; do \
		dbus-launch ./runner $$test; \
	done

AM_CFLAGS = \
	-I$(top_srcdir)/common \
	$(DUP_CFLAGS) \
	-w

LDADD = \
	$(DUP_LIBS) \
	@INTLLIBS@ \
	$(top_builddir)/common/libcommon.la

runner_VALASOURCES = \
	runner.vala

runner_SOURCES = \
	$(runner_VALASOURCES)

AM_VALAFLAGS = \
	--vapidir $(top_srcdir)/common \
	--vapidir $(top_srcdir)/vapi \
	$(NETWORKMONITOR_VALAFLAGS) \
	--pkg config \
	--pkg gio-2.0 \
	--pkg libpeas-1.0 \
	--pkg posix \
	--pkg libcommon

runner_vala.stamp: $(top_srcdir)/config.h

dist-hook:
	cd $(distdir) && rm $(runner_VALASOURCES:.vala=.c) \
	                    runner_vala.stamp

EXTRA_DIST = \
	mock

CLEANFILES = runner_vala.stamp
