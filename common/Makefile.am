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

noinst_LTLIBRARIES = libcommon.la

VALA_CFLAGS = \
	--library=libcommon \
	--vapidir $(top_srcdir)/vapi \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	--pkg gnome-keyring-1 \
	--pkg posix \
	--pkg config

AM_CFLAGS = \
	$(COMMON_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

libcommon_la_VALASOURCES = \
	Backend.vala \
	BackendFile.vala \
	BackendS3.vala \
	CommonUtils.vala \
	Duplicity.vala \
	DuplicityInfo.vala \
	DuplicityInstance.vala \
	Network.vala \
	Operation.vala \
	OperationBackup.vala \
	OperationRestore.vala \
	OperationStatus.vala \
	OperationFiles.vala \
	RecursiveDelete.vala \
	RecursiveMove.vala \
	RecursiveOp.vala

libcommon_la_BUILTSOURCES = \
	common.h \
	$(libcommon_la_VALASOURCES:.vala=.c)

libcommon_la_SOURCES = \
	chacks.c chacks.h \
	$(libcommon_la_BUILTSOURCES)

$(libcommon_la_BUILTSOURCES): vala.stamp
vala.stamp: $(libcommon_la_VALASOURCES)
if USE_VALAC
	$(AM_V_GEN)$(VALAC) -C -H common.h $(VALA_CFLAGS) $^
	@touch $@
else
	@echo "ERROR: Valac compilation is disabled, but the C sources are out-of-date."
	@exit 1
endif

libcommon_la_LIBADD = $(COMMON_LIBS) @INTLLIBS@

EXTRA_DIST = vala.stamp $(libcommon_la_VALASOURCES)
