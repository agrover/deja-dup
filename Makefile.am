SUBDIRS = data po vapi libdeja-dup monitor preferences deja-dup

# Distribute pot file
dist-hook:
	$(MAKE) -C "$(srcdir)/po" "$(GETTEXT_PACKAGE).pot"
	cp "$(srcdir)/po/$(GETTEXT_PACKAGE).pot" "$(distdir)/po/"

ACLOCAL_AMFLAGS = -I m4
EXTRA_DIST = autogen.sh intltool-extract.in intltool-merge.in intltool-update.in
DISTCLEANFILES = intltool-extract intltool-merge intltool-update

