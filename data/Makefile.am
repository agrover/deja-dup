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

nobase_dist_data_DATA = \
	icons/hicolor/scalable/apps/deja-dup.svg \
	icons/hicolor/scalable/apps/deja-dup-symbolic.svg \
	icons/hicolor/scalable/actions/deja-dup-backup.svg \
	icons/hicolor/scalable/actions/deja-dup-restore.svg

@INTLTOOL_SCHEMAS_RULE@
schemadir = $(sysconfdir)/gconf/schemas
schema_in_file = deja-dup.schemas.in
dist_schema_DATA = $(schema_in_file:.schemas.in=.schemas)

@INTLTOOL_XML_NOMERGE_RULE@

gsettings_SCHEMAS = org.gnome.deja-dup.gschema.xml
@GSETTINGS_RULES@

@INTLTOOL_DESKTOP_RULE@
desktopdir = $(datadir)/applications
dist_desktop_DATA = deja-dup.desktop
deja-dup-monitor.desktop.in: deja-dup-monitor.desktop.in.in
	sed "s|@pkglibdir@|$(pkglibdir)|g" $^ > $@

autostartdir = $(sysconfdir)/xdg/autostart
dist_autostart_DATA = deja-dup-monitor.desktop

EXTRA_DIST = deja-dup.schemas.in deja-dup.desktop.in deja-dup-monitor.desktop.in.in org.gnome.deja-dup.gschema.xml
DISTCLEANFILES = deja-dup.schemas deja-dup.desktop deja-dup-monitor.desktop deja-dup-monitor.desktop.in $(gsettings_SCHEMAS)

if GCONF_SCHEMAS_INSTALL
install-data-local:
	-GCONF_CONFIG_SOURCE=$(GCONF_SCHEMA_CONFIG_SOURCE) \
	$(GCONFTOOL) --makefile-install-rule $(dist_schema_DATA)
endif

if GCONF_SCHEMAS_INSTALL
uninstall-local:
	-GCONF_CONFIG_SOURCE=$(GCONF_SCHEMA_CONFIG_SOURCE) \
	$(GCONFTOOL) --makefile-uninstall-rule $(dist_schema_DATA)
endif

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

