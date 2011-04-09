# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# © 2008–2010 Michael Terry <mike@mterry.name>
#
# Déjà Dup is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Déjà Dup is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Déjà Dup.  If not, see <http://www.gnu.org/licenses/>.

# Here's a bunch of translation support.  Some stolen from dpkg

POLINGUAS = $(shell grep -v "^\#" $(top_srcdir)/po/LINGUAS)
LINGUAS = C $(POLINGUAS)

PAGES = deja-dup.1

C/stamp: $(srcdir)/include.main $(top_builddir)/deja-dup/deja-dup
	@$(mkdir_p) C
	@$(srcdir)/help2man -N -i $(srcdir)/include.main -L en_US.UTF-8 $(top_builddir)/deja-dup/deja-dup > C/deja-dup.1
	$(AM_V_GEN)touch $@

%/stamp: $(top_builddir)/po/%.gmo $(srcdir)/include.main $(top_builddir)/deja-dup/deja-dup
	@$(mkdir_p) locales/$*/LC_MESSAGES
	@$(mkdir_p) $*
	@cp $(top_builddir)/po/$*.gmo locales/$*/LC_MESSAGES/deja-dup.mo
	@DEJA_DUP_LOCALEDIR=$(abs_builddir)/locales DEJA_DUP_LANGUAGE=$* $(srcdir)/help2man -N -i $(srcdir)/include.main -L en_US.UTF-8 $(top_builddir)/deja-dup/deja-dup > $*/deja-dup.1
	$(AM_V_GEN)touch $@

man: $(patsubst %,%/stamp,$(LINGUAS))

EXTRA_DIST = help2man include.main

clean-local: clean-local-@USE_NLS@
distclean-local: clean-local-@USE_NLS@
mostlyclean-local: clean-local-@USE_NLS@
maintainer-clean-local: clean-local-@USE_NLS@
clean-local-no:
clean-local-yes:
	rm -fr $(LINGUAS) locales

install-data-local: install-data-local-@USE_NLS@
install-data-local-no:
install-data-local-yes: man
	for lang in $(POLINGUAS); do \
		$(mkinstalldirs) "$(DESTDIR)$(mandir)/$$lang/man1"; \
		$(INSTALL_DATA) $$lang/*.1 "$(DESTDIR)$(mandir)/$$lang/man1"; \
	done
	$(mkinstalldirs) "$(DESTDIR)$(mandir)/man1"; \
	$(INSTALL_DATA) C/*.1 "$(DESTDIR)$(mandir)/man1";

uninstall-local: uninstall-local-@USE_NLS@
uninstall-local-no:
uninstall-local-yes: man
	for lang in $(POLINGUAS); do \
		for file in $(PAGES); do \
			rm -f "$(DESTDIR)$(mandir)/$$lang/man1/$$file"; \
		done \
	done
	for file in $(PAGES); do \
		rm -f "$(DESTDIR)$(mandir)/man1/$$file"; \
	done

dist-hook: man
