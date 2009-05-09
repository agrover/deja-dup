# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-

SUBDIRS = data po vapi libdeja-dup applet monitor preferences deja-dup nautilus help tests

# Distribute pot file
update-po:
	rm "po/$(GETTEXT_PACKAGE).pot"
	$(MAKE) -C "$(srcdir)/po" "$(GETTEXT_PACKAGE).pot"
	$(MAKE) -C "$(srcdir)/help" update-po
dist-hook:
	cd "$(distdir)/po" && INTLTOOL_EXTRACT=@INTLTOOL_EXTRACT@ srcdir=$(srcdir) @INTLTOOL_UPDATE@ --gettext-package $(GETTEXT_PACKAGE) --pot
	for lang in $(shell cat "$(srcdir)/po/LINGUAS"); do \
		msgmerge $(srcdir)/po/$$lang.po "$(distdir)/po/$(GETTEXT_PACKAGE).pot" -o $(distdir)/po/$$lang.po; \
	done

ACLOCAL_AMFLAGS = -I m4

DISTCHECK_CONFIGURE_FLAGS = --disable-scrollkeeper

EXTRA_DIST = \
	autogen.sh \
	intltool-extract.in \
	intltool-merge.in \
	intltool-update.in \
	COPYING-DOCS \
	gnome-doc-utils.make

DISTCLEANFILES = \
	intltool-extract \
	intltool-merge \
	intltool-update \
	gnome-doc-utils.make

