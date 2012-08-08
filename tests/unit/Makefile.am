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
	unit-tests \
	network

check:
	@dbus-launch ./unit-tests

AM_CFLAGS = \
	-I$(top_srcdir)/common \
	$(COMMON_CFLAGS) \
	-w

LDADD = \
	$(COMMON_LIBS) \
	@INTLLIBS@ \
	$(top_builddir)/common/libcommon.la

unit_tests_VALASOURCES = \
	unit-tests.vala

unit_tests_SOURCES = \
	$(unit_tests_VALASOURCES)

network_VALASOURCES = \
	network.vala

network_SOURCES = \
	$(network_VALASOURCES)

AM_VALAFLAGS = \
	--vapidir $(top_srcdir)/common \
	--vapidir $(top_srcdir)/vapi \
	$(NETWORKMONITOR_VALAFLAGS) \
	--pkg config \
	--pkg gio-2.0 \
	--pkg libpeas-1.0 \
	--pkg posix \
	--pkg libcommon

unit_tests_vala.stamp: $(top_srcdir)/config.h
network_vala.stamp: $(top_srcdir)/config.h

dist-hook:
	cd $(distdir) && rm $(unit_tests_VALASOURCES:.vala=.c) \
	                    unit_tests_vala.stamp
	cd $(distdir) && rm $(network_VALASOURCES:.vala=.c) \
	                    network_vala.stamp

CLEANFILES = unit_tests_vala.stamp network_vala.stamp
