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

pkglib_LTLIBRARIES = libcommon.la

libcommon_la_CFLAGS = \
	$(COMMON_CFLAGS) \
	-w \
	-DPKG_LIBEXEC_DIR=\"$(pkglibexecdir)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

libcommon_la_LDFLAGS = -avoid-version

libcommon_la_LIBADD = \
	$(COMMON_LIBS) \
	@INTLLIBS@

noinst_HEADERS = \
	chacks.h \
	uriutils.h

libcommon_la_VALASOURCES = \
	AsyncCommand.vala \
	Backend.vala \
	BackendAuto.vala \
	BackendFile.vala \
	BackendRackspace.vala \
	BackendS3.vala \
	BackendU1.vala \
	Checker.vala \
	CommonUtils.vala \
	DirHandling.vala \
	Network.vala \
	Operation.vala \
	OperationBackup.vala \
	OperationFiles.vala \
	OperationRestore.vala \
	OperationStatus.vala \
	OperationVerify.vala \
	PythonChecker.vala \
	RecursiveDelete.vala \
	RecursiveMove.vala \
	RecursiveOp.vala \
	SimpleSettings.vala \
	ToolPlugin.vala

libcommon_la_SOURCES = \
	chacks.c \
	uriutils.c \
	$(libcommon_la_VALASOURCES)

AM_VALAFLAGS = \
	--library=libcommon \
	-H common.h \
	--vapidir=$(top_srcdir)/vapi \
	$(SHARED_VALAFLAGS) \
	$(NETWORKMONITOR_VALAFLAGS) \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	--pkg gnome-keyring-1 \
	--pkg libpeas-1.0 \
	--pkg uriutils \
	--pkg posix \
	--pkg config

libcommon_la_vala.stamp: $(top_srcdir)/config.h

dist-hook:
	cd $(distdir) && rm -f $(libcommon_la_VALASOURCES:.vala=.c) \
	                       common.h libcommon_la_vala.stamp

CLEANFILES = libcommon_la_vala.stamp
