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

noinst_LTLIBRARIES = libwidgets.la

libwidgets_la_CFLAGS = \
	-I$(top_srcdir)/common \
	$(WIDGETS_CFLAGS) \
	$(APPINDICATOR_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

libwidgets_la_LIBADD = $(WIDGETS_LIBS) $(APPINDICATOR_LIBS) @INTLLIBS@ $(top_builddir)/common/libcommon.la

libwidgets_la_VALASOURCES = \
	ButtonConnect.vala \
	ConfigBool.vala \
	ConfigChoice.vala \
	ConfigDelete.vala \
	ConfigEntry.vala \
	ConfigFolder.vala \
	ConfigLabel.vala \
	ConfigLabelBool.vala \
	ConfigLabelList.vala \
	ConfigLabelLocation.vala \
	ConfigLabelPolicy.vala \
	ConfigList.vala \
	ConfigLocation.vala \
	ConfigLocationDAV.vala \
	ConfigLocationFile.vala \
	ConfigLocationFTP.vala \
	ConfigLocationRackspace.vala \
	ConfigLocationS3.vala \
	ConfigLocationSSH.vala \
	ConfigLocationSMB.vala \
	ConfigLocationTable.vala \
	ConfigLocationU1.vala \
	ConfigLocationVolume.vala \
	ConfigNumber.vala \
	ConfigPeriod.vala \
	ConfigRelPath.vala \
	ConfigURLPart.vala \
	ConfigURLPartBool.vala \
	ConfigWidget.vala \
	ToggleGroup.vala \
	WidgetUtils.vala

libwidgets_la_VALABUILTSOURCES = \
	widgets.h \
	$(libwidgets_la_VALASOURCES:.vala=.c)

libwidgets_la_SOURCES = \
	whacks.c whacks.h \
	$(libwidgets_la_VALABUILTSOURCES)

if MAINTAINER_MODE
PACKAGES = \
	--pkg libcommon \
	--pkg @GTK_MODULE@ \
	--pkg uriutils \
	--pkg config
BUILT_SOURCES = vala.stamp
vala.stamp: $(libwidgets_la_VALASOURCES)
	$(AM_V_GEN)$(VALAC) --library=libwidgets -H widgets.h --vapidir=$(top_srcdir)/vapi \
	                    --vapidir=$(top_srcdir)/common $(PACKAGES) $^ -C
	touch $@
endif

EXTRA_DIST = $(libwidgets_la_VALASOURCES)
if MAINTAINER_MODE
CLEANFILES = $(BUILT_SOURCES) $(libwidgets_la_VALABUILTSOURCES)
endif
