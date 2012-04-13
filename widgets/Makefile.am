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

noinst_LTLIBRARIES = libwidgets.la

libwidgets_la_CFLAGS = \
	-I$(top_srcdir)/common \
	$(WIDGETS_CFLAGS) \
	$(UNITY_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

libwidgets_la_LIBADD = \
	$(WIDGETS_LIBS) \
	$(UNITY_LIBS) \
	@INTLLIBS@ \
	$(top_builddir)/common/libcommon.la

libwidgets_la_VALASOURCES = \
	ConfigBool.vala \
	ConfigChoice.vala \
	ConfigDelete.vala \
	ConfigEntry.vala \
	ConfigFolder.vala \
	ConfigLabel.vala \
	ConfigLabelBackupDate.vala \
	ConfigLabelBool.vala \
	ConfigLabelList.vala \
	ConfigLabelLocation.vala \
	ConfigLabelPolicy.vala \
	ConfigList.vala \
	ConfigLocation.vala \
	ConfigLocationCustom.vala \
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
	ConfigSwitch.vala \
	ConfigURLPart.vala \
	ConfigURLPartBool.vala \
	ConfigWidget.vala \
	ToggleGroup.vala \
	WidgetUtils.vala

libwidgets_la_SOURCES = \
	$(libwidgets_la_VALASOURCES)

AM_VALAFLAGS = \
	--library=libwidgets \
	-H widgets.h \
	--vapidir=$(top_srcdir)/common \
	--vapidir=$(top_srcdir)/vapi \
	$(SHARED_VALAFLAGS) \
	$(UNITY_VALAFLAGS) \
	--pkg libcommon \
	--pkg @GTK_MODULE@ \
	--pkg libpeas-1.0 \
	--pkg uriutils \
	--pkg libnotify \
	--pkg config

libwidgets_la_vala.stamp: $(top_srcdir)/config.h

dist-hook:
	cd $(distdir) && rm -f $(libwidgets_la_VALASOURCES:.vala=.c) \
	                       widgets.h libwidgets_la_vala.stamp

