# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-

SUBDIRS = data po vapi libdeja-dup applet monitor preferences deja-dup nautilus help tests

# Distribute pot file
update-pot:
	$(MAKE) -C po "$(GETTEXT_PACKAGE).pot"
	$(MAKE) -C help update-pot
dist-hook: update-pot

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

