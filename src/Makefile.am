bin_PROGRAMS = deja-dup

VALA_CFLAGS = \
  --vapidir $(top_srcdir)/vapi \
  --pkg gtk+-2.0 \
  --pkg gio-2.0 \
  --pkg gconf-2.0 \
  --pkg libgnomeui-2.0 \
  --pkg gnome-keyring-1 \
  --pkg PassphraseSchema \
  --pkg config

AM_CFLAGS = \
  $(GTK_CFLAGS) \
  $(DEBUG_CFLAGS) \
  -DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

deja_dup_VALASOURCES = \
	Backend.vala \
	BackendFile.vala \
	BackendS3.vala \
	Backup.vala \
	ConfigBackend.vala \
	ConfigBool.vala \
	ConfigChoice.vala \
	ConfigEntry.vala \
	ConfigFolder.vala \
	ConfigList.vala \
	ConfigWidget.vala \
	Duplicity.vala \
	MainWindow.vala \
	Operation.vala \
	PreferencesDialog.vala \
	Restore.vala \
	main.vala

BUILT_SOURCES = \
	deja-dup.stamp

deja_dup_SOURCES = \
	PassphraseSchema.c PassphraseSchema.h \
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

deja_dup_LDADD = $(GTK_LIBS) @INTLLIBS@

EXTRA_DIST = deja-dup.stamp
DISTCLEANFILES = \
	$(BUILT_SOURCES) \
	$(deja_dup_VALASOURCES:.vala=.c) \
	$(deja_dup_VALASOURCES:.vala=.h)

