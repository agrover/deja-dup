# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-

bin_PROGRAMS = deja-dup-preferences

VALA_CFLAGS = \
	--vapidir $(top_srcdir)/libdeja-dup \
	--vapidir $(top_srcdir)/vapi \
	--pkg gtk+-2.0 \
	--pkg gio-2.0 \
	--pkg gconf-2.0 \
	--pkg unique-1.0 \
	--pkg libdeja-dup \
	--pkg unix \
	--pkg config

AM_CFLAGS = \
	-I$(top_srcdir)/libdeja-dup \
	$(PREF_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

deja_dup_preferences_VALASOURCES = \
	ConfigBackend.vala \
	ConfigBool.vala \
	ConfigChoice.vala \
	ConfigEntry.vala \
	ConfigFolder.vala \
	ConfigList.vala \
	ConfigNumber.vala \
	ConfigPeriod.vala \
	ConfigWidget.vala \
	PreferencesDialog.vala \
	ToggleGroup.vala \
	preferences.vala

BUILT_SOURCES = \
	deja-dup-preferences.stamp

deja_dup_preferences_SOURCES = \
	$(deja_dup_preferences_VALASOURCES:.vala=.c) \
	$(deja_dup_preferences_VALASOURCES)

deja-dup-preferences.stamp: $(deja_dup_preferences_VALASOURCES)
if USE_VALAC
	$(VALAC) -C $(VALA_CFLAGS) $^
	touch $@
else
	@echo "ERROR: Valac compilation is disabled, but the C sources are out-of-date."
	@exit 1
endif

deja_dup_preferences_LDADD = $(PREF_LIBS) @INTLLIBS@ $(top_builddir)/libdeja-dup/libdeja-dup.la

EXTRA_DIST = deja-dup-preferences.stamp
DISTCLEANFILES = \
	$(BUILT_SOURCES) \
	$(deja_dup_preferences_VALASOURCES:.vala=.c) \
	$(deja_dup_preferences_VALASOURCES:.vala=.h)

