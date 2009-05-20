# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-

noinst_LTLIBRARIES = libdeja-dup.la

VALA_CFLAGS = \
	--library=libdeja-dup \
	--vapidir $(top_srcdir)/vapi \
	--pkg gtk+-2.0 \
	--pkg gio-2.0 \
	--pkg gconf-2.0 \
	--pkg libgnomeui-2.0 \
	--pkg libnotify \
	--pkg gnome-keyring-1 \
	--pkg dbus-glib-1 \
	--pkg gdk-x11-2.0 \
	--pkg unique-1.0 \
	--pkg posix \
	--pkg hacks \
	--pkg PassphraseSchema \
	--pkg unix \
	--pkg config

AM_CFLAGS = \
	$(LIBRARY_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

libdeja_dup_la_VALASOURCES = \
	Backend.vala \
	BackendFile.vala \
	BackendS3.vala \
	BackendSSH.vala \
	ConfigBackend.vala \
	ConfigBool.vala \
	ConfigChoice.vala \
	ConfigEntry.vala \
	ConfigList.vala \
	ConfigLocation.vala \
	ConfigNumber.vala \
	ConfigPeriod.vala \
	ConfigWidget.vala \
	Duplicity.vala \
	DuplicityInfo.vala \
	DuplicityInstance.vala \
	Operation.vala \
	OperationBackup.vala \
	OperationRestore.vala \
	OperationStatus.vala \
	RecursiveDelete.vala \
	RecursiveMove.vala \
	RecursiveOp.vala \
	ToggleGroup.vala \
	libdeja-dup.vala

BUILT_SOURCES = \
	vala.stamp

libdeja_dup_la_SOURCES = \
	hacks.c hacks.h \
	mountoperation.c mountoperation.h \
	PassphraseSchema.c PassphraseSchema.h \
	deja-dup.h \
	$(libdeja_dup_la_VALASOURCES:.vala=.c) \
	$(libdeja_dup_la_VALASOURCES)

vala.stamp: $(libdeja_dup_la_VALASOURCES)
if USE_VALAC
	$(VALAC) -C -H deja-dup.h $(VALA_CFLAGS) $^
	touch $@
else
	@echo "ERROR: Valac compilation is disabled, but the C sources are out-of-date."
	@exit 1
endif

libdeja_dup_la_LIBADD = $(LIBRARY_LIBS) @INTLLIBS@

EXTRA_DIST = vala.stamp
DISTCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libdeja_dup_la_VALASOURCES:.vala=.c) \
	$(libdeja_dup_la_VALASOURCES:.vala=.h)

