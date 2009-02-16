# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-

bin_PROGRAMS = deja-dup-monitor

VALA_CFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--pkg gconf-2.0 \
	--pkg config

AM_CFLAGS = \
	$(MONITOR_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

deja_dup_monitor_VALASOURCES = \
	monitor.vala

BUILT_SOURCES = \
	deja-dup-monitor.stamp

deja_dup_monitor_SOURCES = \
	$(deja_dup_monitor_VALASOURCES:.vala=.c) \
	$(deja_dup_monitor_VALASOURCES:.vala=.h) \
	$(deja_dup_monitor_VALASOURCES)

deja-dup-monitor.stamp: $(deja_dup_monitor_VALASOURCES)
if USE_VALAC
	$(VALAC) -C $(VALA_CFLAGS) $^
	touch $@
else
	@echo "ERROR: Valac compilation is disabled, but the C sources are out-of-date."
	@exit 1
endif

deja_dup_monitor_LDADD = $(MONITOR_LIBS) @INTLLIBS@

EXTRA_DIST = deja-dup-monitor.stamp
DISTCLEANFILES = \
	$(BUILT_SOURCES) \
	$(deja_dup_monitor_VALASOURCES:.vala=.c) \
	$(deja_dup_monitor_VALASOURCES:.vala=.h)

