# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-

SUBDIRS = data po vapi libdeja-dup applet monitor preferences deja-dup nautilus help tests

# Distribute pot file
update-po:
	rm "$(srcdir)/po/$(GETTEXT_PACKAGE).pot"
	$(MAKE) -C "$(srcdir)/po" "$(GETTEXT_PACKAGE).pot"
	cp "$(srcdir)/po/$(GETTEXT_PACKAGE).pot" "$(srcdir)/po/$(GETTEXT_PACKAGE).simple.pot"
	$(MAKE) -C "$(srcdir)/help" update-po
dist-hook: update-po
	cp "$(srcdir)/po/$(GETTEXT_PACKAGE).pot" "$(distdir)/po/"
	for lang in $(shell cat "$(srcdir)/po/LINGUAS"); do \
		msgmerge po/$$lang.po "$(srcdir)/po/$(GETTEXT_PACKAGE).simple.pot" -o po/$$lang.po; \
	done

ACLOCAL_AMFLAGS = -I m4

DISTCHECK_CONFIGURE_FLAGS = --disable-scrollkeeper

EXTRA_DIST = \
	autogen.sh \
	intltool-extract.in \
	intltool-merge.in \
	intltool-update.in \
	gnome-doc-utils.make

DISTCLEANFILES = \
	intltool-extract \
	intltool-merge \
	intltool-update \
	gnome-doc-utils.make

