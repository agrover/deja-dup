# -*- indent-tabs-mode: t; tab-width: 2 -*-

bin_PROGRAMS = deja-dup

VALA_CFLAGS = \
	--vapidir $(top_srcdir)/libdeja-dup \
	--vapidir $(top_srcdir)/vapi \
	--pkg gtk+-2.0 \
	--pkg gio-2.0 \
	--pkg gconf-2.0 \
	--pkg libgnomeui-2.0 \
	--pkg gnome-keyring-1 \
	--pkg libdeja-dup \
	--pkg config

AM_CFLAGS = \
	-I$(top_srcdir)/libdeja-dup \
	$(DUP_CFLAGS) \
	$(DEBUG_CFLAGS) \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

deja_dup_VALASOURCES = \
	AssistantBackup.vala \
	AssistantOperation.vala \
	AssistantRestore.vala \
	MainWindow.vala \
	main.vala

BUILT_SOURCES = \
	deja-dup.stamp

deja_dup_SOURCES = \
	$(deja_dup_VALASOURCES:.vala=.c) \
	$(deja_dup_VALASOURCES:.vala=.h) \
	$(deja_dup_VALASOURCES)

deja-dup.stamp: $(deja_dup_VALASOURCES)
if USE_VALAC
	$(VALAC) -C $(VALA_CFLAGS) $^
	touch $@
else
	@echo "ERROR: Valac compilation is disabled, but the C sources are out-of-date."
	@exit 1
endif

deja_dup_LDADD = $(DUP_LIBS) @INTLLIBS@ $(top_builddir)/libdeja-dup/libdeja-dup.la

EXTRA_DIST = deja-dup.stamp
DISTCLEANFILES = \
	$(BUILT_SOURCES) \
	$(deja_dup_VALASOURCES:.vala=.c) \
	$(deja_dup_VALASOURCES:.vala=.h)

