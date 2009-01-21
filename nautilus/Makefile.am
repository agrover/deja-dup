# -*- indent-tabs-mode: t; tab-width: 2 -*-

nautilusdir = $(NAUTILUS_EXTENSION_DIR)

nautilus_LTLIBRARIES = libnautilus-deja-dup.la

VALA_CFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--pkg config

AM_CFLAGS = \
	$(NAUTILUS_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

libnautilus_deja_dup_la_VALASOURCES = \
	nautilus.vala

BUILT_SOURCES = \
	vala.stamp

libnautilus_deja_dup_la_SOURCES = \
	$(libnautilus_deja_dup_la_VALASOURCES:.vala=.c) \
	$(libnautilus_deja_dup_la_VALASOURCES:.vala=.h) \
	$(libnautilus_deja_dup_la_VALASOURCES)

vala.stamp: $(libnautilus_deja_dup_la_VALASOURCES)
if USE_VALAC
	$(VALAC) -C $(VALA_CFLAGS) $^
	touch $@
else
	@echo "ERROR: Valac compilation is disabled, but the C sources are out-of-date."
	@exit 1
endif

libnautilus_deja_dup_la_LDFLAGS = -module -avoid-version
libnautilus_deja_dup_la_LIBADD = $(NAUTILUS_LIBS) @INTLLIBS@

EXTRA_DIST = vala.stamp
DISTCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libnautilus_deja_dup_la_VALASOURCES:.vala=.c) \
	$(libnautilus_deja_dup_la_VALASOURCES:.vala=.h)

