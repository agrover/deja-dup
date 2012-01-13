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

nobase_dist_data_DATA = \
	icons/hicolor/16x16/apps/deja-dup.png \
	icons/hicolor/22x22/apps/deja-dup.png \
	icons/hicolor/24x24/apps/deja-dup.png \
	icons/hicolor/32x32/apps/deja-dup.png \
	icons/hicolor/48x48/apps/deja-dup.png \
	icons/hicolor/256x256/apps/deja-dup.png \
	icons/hicolor/scalable/apps/deja-dup-symbolic.svg \
	icons/hicolor/scalable/devices/deja-dup-cloud.svg

nobase_dist_pkgdata_DATA = \
	ui/restore-missing.ui

@INTLTOOL_XML_NOMERGE_RULE@

@GSETTINGS_RULES@
gsettings_SCHEMAS = org.gnome.DejaDup.gschema.xml

@INTLTOOL_DESKTOP_RULE@
desktopdir = $(datadir)/applications
desktop_DATA = deja-dup.desktop deja-dup-preferences.desktop

if HAVE_CCPANEL
desktop_DATA += deja-dup-ccpanel.desktop
endif

deja-dup-preferences.desktop.in: deja-dup-preferences.desktop.in.in
	$(install_sh_DATA) $^ $@
if HAVE_CCPANEL
	sed -i "s/^Categories=.*/\0\n\nNotShowIn=$(shell grep OnlyShowIn $(srcdir)/deja-dup-ccpanel.desktop.in | cut -d= -f2)/" $@
endif

deja-dup-monitor.desktop.in: deja-dup-monitor.desktop.in.in
	sed "s|@pkglibexecdir@|$(pkglibexecdir)|g" $^ > $@

autostartdir = $(sysconfdir)/xdg/autostart
autostart_DATA = deja-dup-monitor.desktop

convertdir = $(datadir)/GConf/gsettings
dist_convert_DATA = deja-dup.convert

EXTRA_DIST = deja-dup.desktop.in deja-dup-ccpanel.desktop.in deja-dup-preferences.desktop.in.in deja-dup-monitor.desktop.in.in org.gnome.DejaDup.gschema.xml.in
CLEANFILES = deja-dup.desktop deja-dup-ccpanel.desktop deja-dup-preferences.desktop deja-dup-preferences.desktop.in deja-dup-monitor.desktop deja-dup-monitor.desktop.in org.gnome.DejaDup.gschema.xml

check: $(desktop_DATA) $(autostart_DATA)
	for desktop in $(desktop_DATA) $(autostart_DATA); do \
		desktop-file-validate $${desktop} || exit 1; \
	done

gtk_update_icon_cache = gtk-update-icon-cache -f -t
install-data-hook: update-icon-cache
uninstall-hook: update-icon-cache

update-icon-cache:
	@-if test -z "$(DESTDIR)"; then \
		echo "Updating Gtk icon cache."; \
		$(gtk_update_icon_cache) $(datadir)/icons/hicolor; \
	else \
		echo "*** Icon cache not updated.  After (un)install, run these:"; \
		echo "***   $(gtk_update_icon_cache) $(datadir)/icons/hicolor"; \
	fi
