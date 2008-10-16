SUBDIRS = data src po vapi

# Grabs all the latest po files from translationproject.org
fetch-po:
	rsync -Lrtvz "translationproject.org::tp/latest/$(GETTEXT_PACKAGE)/" po

# Distribute pot file
dist-hook:
	$(MAKE) -C "$(srcdir)/po" "$(GETTEXT_PACKAGE).pot"
	cp "$(srcdir)/po/$(GETTEXT_PACKAGE).pot" "$(distdir)/po/"

EXTRA_DIST = autogen.sh intltool-extract.in intltool-merge.in intltool-update.in
DISTCLEANFILES = intltool-extract intltool-merge intltool-update

