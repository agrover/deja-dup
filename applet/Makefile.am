bin_PROGRAMS = deja-dup-applet

VALA_CFLAGS = \
  --vapidir $(top_srcdir)/libdeja-dup \
  --vapidir $(top_srcdir)/vapi \
  --pkg gtk+-2.0 \
  --pkg gconf-2.0 \
  --pkg libnotify \
  --pkg libdeja-dup \
  --pkg hacks \
  --pkg config

AM_CFLAGS = \
  -I$(top_srcdir)/libdeja-dup \
  $(APPLET_CFLAGS) \
  $(DEBUG_CFLAGS) \
  -DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

deja_dup_applet_VALASOURCES = \
    StatusIcon.vala \
	applet.vala

BUILT_SOURCES = \
	deja-dup-applet.stamp

deja_dup_applet_SOURCES = \
	$(deja_dup_applet_VALASOURCES:.vala=.c) \
	$(deja_dup_applet_VALASOURCES:.vala=.h) \
	$(deja_dup_applet_VALASOURCES)

deja-dup-applet.stamp: $(deja_dup_applet_VALASOURCES)
if USE_VALAC
	$(VALAC) -C $(VALA_CFLAGS) $^
	touch $@
else
	@echo "ERROR: Valac compilation is disabled, but the C sources are out-of-date."
	@exit 1
endif

deja_dup_applet_LDADD = $(APPLET_LIBS) @INTLLIBS@ $(top_srcdir)/libdeja-dup/libdeja-dup.la

EXTRA_DIST = deja-dup-applet.stamp
DISTCLEANFILES = \
	$(BUILT_SOURCES) \
	$(deja_dup_applet_VALASOURCES:.vala=.c) \
	$(deja_dup_applet_VALASOURCES:.vala=.h)

