# -*- indent-tabs-mode: t; tab-width: 2 -*-

nautilusdir = $(NAUTILUS_EXTENSION_DIR)

nautilus_LTLIBRARIES = libnautilus-deja-dup.la

AM_CFLAGS = \
	$(NAUTILUS_CFLAGS) \
	$(DEBUG_CFLAGS)

libnautilus_deja_dup_la_SOURCES = \
	NautilusExtension.c NautilusExtension.h

libnautilus_deja_dup_la_LDFLAGS = -module -avoid-version
libnautilus_deja_dup_la_LIBADD = $(NAUTILUS_LIBS) @INTLLIBS@

