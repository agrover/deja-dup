# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-

# Turn off g-d-u's attempt at translating docs -- po4a does it for us.
# This is very hacky, true.
_xml2po = cp ../$(srcdir)/$@ $(notdir $@).tmp && chmod u+w $(notdir $@).tmp || true

clean-local: clean-local-@USE_NLS@
distclean-local: clean-local-@USE_NLS@
mostlyclean-local: clean-local-@USE_NLS@
maintainer-clean-local: clean-local-@USE_NLS@

include $(top_srcdir)/gnome-doc-utils.make

dist_man1_MANS = \
	C/deja-dup.1 \
	C/deja-dup-applet.1 \
	C/deja-dup-monitor.1 \
	C/deja-dup-preferences.1

DOC_MODULE = deja-dup
DOC_ENTITIES = 
DOC_INCLUDES = 
DOC_FIGURES = 

# Here's a bunch of translation support.  It's largely stolen from dpkg

# Extract the list of languages from the po4a config and po/LINGUAS files.
PO4A_LINGUAS = $(shell sed -ne 's/^.*\[po4a_langs\] \(.*\)$$/\1/p' $(srcdir)/po4a.cfg)
LINGUAS = $(shell cat $(top_srcdir)/po/LINGUAS)
DOC_LINGUAS = $(LINGUAS)

all-local: all-local-@USE_NLS@
all-local-no:
all-local-yes: po4a.stamp

# Put LINGUAS list into po4a.cfg, but only if needed (else we'll update
# timestamp on the cfg file unnecessarily.  Also copy all the po files from the
# real po directory into the sub language directories in help where po4a looks
# for them.  po4a modifies those po files, so we don't want it to access the
# real ones.
prepare.stamp: po4a.cfg $(top_srcdir)/po/LINGUAS
	for lang in C $(LINGUAS); do \
		$(mkdir_p) $$lang; \
		test "$(srcdir)" = "." || cp -ar $(srcdir)/$$lang/* $$lang; \
	done
	test "$(PO4A_LINGUAS)" = "$(LINGUAS)" || sed -i "s/^\(.*\[po4a_langs\] \).*$$/\1$(LINGUAS)/" $(srcdir)/po4a.cfg
	touch $@

po4a.stamp: po4a.cfg $(dist_man1_MANS) C/deja-dup.xml prepare.stamp  $(top_srcdir)/po/*.po
	test -e $(srcdir)/no-po4a || $(PO4A) --no-backups --variable srcdir=$(srcdir) --variable top_srcdir=$(top_srcdir) $(srcdir)/po4a.cfg
	touch $@

clean-local-no:
clean-local-yes:
	for lang in $(LINGUAS); do \
		if [ -d $$lang ]; then \
			rm -f $$(echo "$(dist_man1_MANS)" | sed "s|C/|$$lang/|g"); \
		fi \
	done
	test "$(srcdir)" = "." || rm -fr C
	test -e $(srcdir)/no-po4a || $(PO4A) --rm-backups --rm-translations --variable top_srcdir=$(top_srcdir) --variable srcdir=$(srcdir) $(srcdir)/po4a.cfg
	rm -f po4a.stamp prepare.stamp

update-po: prepare.stamp
	test -e $(srcdir)/no-po4a || $(PO4A) --no-backups --force --no-translations --variable srcdir=$(srcdir) $(srcdir)/po4a.cfg
	test -e $(srcdir)/no-po4a || msgcat --use-first $(top_srcdir)/po/deja-dup.pot deja-dup-help.pot -o ../po/deja-dup.pot

install-data-local: install-data-local-@USE_NLS@
install-data-local-no:
install-data-local-yes:
	for lang in $(LINGUAS); do \
		if [ -d $$lang ]; then \
			files=$$(echo "$(dist_man1_MANS)" | sed "s|C/|$$lang/|g"); \
			$(MAKE) install-man \
				mandir="$(mandir)/$$lang" \
				man_MANS="" \
				dist_man1_MANS="$$files"; \
		fi \
	done

uninstall-local: uninstall-local-@USE_NLS@
uninstall-local-no:
uninstall-local-yes:
	for lang in $(LINGUAS); do \
		if [ -d $$lang ]; then \
			files=$$(echo "$(dist_man1_MANS)" | sed "s|C/|$$lang/|g"); \
			$(MAKE) uninstall-man \
				mandir="$(mandir)/$$lang" \
				man_MANS="" \
				dist_man1_MANS="$$files"; \
		fi \
	done

dist-hook: po4a.stamp doc-dist-hook
	cp po4a.stamp $(distdir)/
	for lang in $(LINGUAS); do \
		$(mkdir_p) $(distdir)/$$lang; \
		cp -r $(srcdir)/$$lang/*.xml $(srcdir)/$$lang/*.1 $(distdir)/$$lang; \
	done
	for lang in C $(LINGUAS); do \
		! test -e $(distdir)/$$lang/deja-dup.xml || sed -i "s/%VERSION%/$(VERSION)/g;s/%DATE%/`date --utc +%F`/g;s/lang=\"C\"/lang=\"$$lang\"/g" $(distdir)/$$lang/*.xml $(distdir)/$$lang/*.1; \
	done
	touch $(distdir)/no-po4a

EXTRA_DIST = po4a.cfg

.PHONY: update-po
