# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# © 2008,2009 Michael Terry <mike@mterry.name>
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

VALA_CFLAGS = \
	--library=libwidgets \
	--vapidir $(top_srcdir)/common \
	--vapidir $(top_srcdir)/vapi \
	--pkg libcommon \
	--pkg gtk+-2.0 \
	--pkg gconf-2.0 \
	--pkg dbus-glib-1 \
	--pkg config

AM_CFLAGS = \
	-I$(top_srcdir)/common \
	$(WIDGETS_CFLAGS) \
	$(APPINDICATOR_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

libwidgets_la_VALASOURCES = \
	ButtonConnect.vala \
	ConfigBool.vala \
	ConfigChoice.vala \
	ConfigDelete.vala \
	ConfigEntry.vala \
	ConfigLabel.vala \
	ConfigLabelBool.vala \
	ConfigLabelList.vala \
	ConfigLabelLocation.vala \
	ConfigList.vala \
	ConfigLocation.vala \
	ConfigNumber.vala \
	ConfigPeriod.vala \
	ConfigWidget.vala \
	ToggleGroup.vala \
	WidgetUtils.vala

BUILT_SOURCES = \
	vala.stamp

libwidgets_la_SOURCES = \
	whacks.c whacks.h \
	widgets.h \
	$(libwidgets_la_VALASOURCES:.vala=.c)

vala.stamp: $(libwidgets_la_VALASOURCES)
if USE_VALAC
	$(AM_V_GEN)$(VALAC) -C -H widgets.h -o $(top_srcdir)/vapi $(VALA_CFLAGS) $^
	@touch $@
else
	@echo "ERROR: Valac compilation is disabled, but the C sources are out-of-date."
	@exit 1
endif

libwidgets_la_LIBADD = $(WIDGETS_LIBS) $(APPINDICATOR_LIBS) @INTLLIBS@ $(top_builddir)/common/libcommon.la

EXTRA_DIST = vala.stamp $(libwidgets_la_VALASOURCES)
