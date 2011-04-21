# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# © 2008,2009,2010,2011 Michael Terry <mike@mterry.name>
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

libcommon_la_CFLAGS = \
	$(COMMON_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DPKG_LIBEXEC_DIR=\"$(pkglibexecdir)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

libcommon_la_LIBADD = $(COMMON_LIBS) @INTLLIBS@

libcommon_la_VALASOURCES = \
	Backend.vala \
	BackendFile.vala \
	BackendRackspace.vala \
	BackendS3.vala \
	BackendU1.vala \
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
	RecursiveOp.vala \
	SimpleSettings.vala

libcommon_la_VALABUILTSOURCES = \
	common.h \
	$(libcommon_la_VALASOURCES:.vala=.c)

libcommon_la_SOURCES = \
	chacks.c chacks.h \
	uriutils.c uriutils.h \
	$(libcommon_la_VALABUILTSOURCES)

if MAINTAINER_MODE
PACKAGES = \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	--pkg gnome-keyring-1 \
	--pkg uriutils \
	--pkg posix \
	--pkg config
BUILT_SOURCES = vala.stamp
vala.stamp: $(libcommon_la_VALASOURCES)
	$(AM_V_GEN)$(VALAC) --library=libcommon -H common.h --vapidir=$(top_srcdir)/vapi $(PACKAGES) $^ -C
	touch $@
endif

EXTRA_DIST = $(libcommon_la_VALASOURCES)
if MAINTAINER_MODE
CLEANFILES = $(BUILT_SOURCES) $(libcommon_la_VALABUILTSOURCES)
endif
