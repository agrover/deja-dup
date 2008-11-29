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
	Duplicity.vala \
	DuplicityInfo.vala \
	Operation.vala \
	OperationBackup.vala \
	OperationCleanup.vala \
	OperationRestore.vala \
	libdeja-dup.vala

BUILT_SOURCES = \
	libdeja-dup.stamp

libdeja_dup_la_SOURCES = \
	PassphraseSchema.c PassphraseSchema.h \
	$(libdeja_dup_la_VALASOURCES:.vala=.c) \
	$(libdeja_dup_la_VALASOURCES:.vala=.h) \
	$(libdeja_dup_la_VALASOURCES)

libdeja-dup.stamp: $(libdeja_dup_la_VALASOURCES)
if USE_VALAC
	$(VALAC) -C $(VALA_CFLAGS) $^
	touch $@
else
	@echo "ERROR: Valac compilation is disabled, but the C sources are out-of-date."
	@exit 1
endif

libdeja_dup_la_LIBADD = $(LIBRARY_LIBS) @INTLLIBS@

EXTRA_DIST = libdeja-dup.stamp
DISTCLEANFILES = \
	$(BUILT_SOURCES) \
	$(libdeja_dup_la_VALASOURCES:.vala=.c) \
	$(libdeja_dup_la_VALASOURCES:.vala=.h)

