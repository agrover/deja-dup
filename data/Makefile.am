# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-

iconappdir = $(datadir)/icons/hicolor/scalable/apps
dist_iconapp_DATA = deja-dup.svg

iconactiondir = $(datadir)/icons/hicolor/scalable/actions
dist_iconaction_DATA = deja-dup-backup.svg deja-dup-restore.svg

@INTLTOOL_SCHEMAS_RULE@
schemadir = $(sysconfdir)/gconf/schemas
schema_in_file = deja-dup.schemas.in
dist_schema_DATA = $(schema_in_file:.schemas.in=.schemas)

@INTLTOOL_DESKTOP_RULE@
desktopdir = $(datadir)/applications
dist_desktop_DATA = deja-dup.desktop

autostartdir = $(sysconfdir)/xdg/autostart
dist_autostart_DATA = deja-dup-monitor.desktop

EXTRA_DIST = deja-dup.schemas.in deja-dup.desktop.in deja-dup-monitor.desktop.in
DISTCLEANFILES = deja-dup.schemas deja-dup.desktop deja-dup-monitor.desktop

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

gtk_update_icon_cache = gtk-update-icon-cache -f -t $(datadir)/icons/hicolor
install-data-hook: update-icon-cache
uninstall-hook: update-icon-cache
update-icon-cache:
	@-if test -z "$(DESTDIR)"; then \
		echo "Updating Gtk icon cache."; \
		$(gtk_update_icon_cache); \
	else \
		echo "*** Icon cache not updated.  After (un)install, run this:"; \
		echo "***   $(gtk_update_icon_cache)"; \
	fi

