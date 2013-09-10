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

SUBDIRS = . tools tests

pkglib_LTLIBRARIES = libdeja.la

libdeja_la_CFLAGS = \
	$(LIBDEJA_CFLAGS) \
	-w \
	-DPKG_LIBEXEC_DIR=\"$(pkglibexecdir)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

libdeja_la_LDFLAGS = -avoid-version

libdeja_la_LIBADD = \
	$(LIBDEJA_LIBS) \
	@INTLLIBS@

noinst_HEADERS = \
	uriutils.h

libdeja_la_VALASOURCES = \
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
	FilteredSettings.vala \
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
	ToolPlugin.vala

libdeja_la_SOURCES = \
	uriutils.c \
	$(libdeja_la_VALASOURCES)

AM_VALAFLAGS = \
	--library=libdeja \
	-H deja.h \
	--vapidir=$(top_srcdir)/vapi \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	--pkg libsecret-1 \
	--pkg secret \
	--pkg libpeas-1.0 \
	--pkg uriutils \
	--pkg posix \
	--pkg config

libdeja_la_vala.stamp: $(top_srcdir)/config.h

dist-hook:
	cd $(distdir) && rm -f $(libdeja_la_VALASOURCES:.vala=.c) \
	                       deja.h libdeja_la_vala.stamp
	rm -f libdeja_la_vala.stamp # Start distcheck workarounds
$(srcdir)/libdeja_la_vala.stamp: chmod-srcdir
chmod-srcdir:
	@chmod u+w $(srcdir) # End distcheck workarounds

CLEANFILES = libdeja_la_vala.stamp

EXTRA_DIST = libdeja.deps
