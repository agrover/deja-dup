# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# For copyright information, see AUTHORS.
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
# and intltool.

ALL_LINGUAS = @ALL_LINGUAS@

PO_LINGUAS=$(shell if test -r $(top_srcdir)/po/LINGUAS; then grep -v "^\#" $(top_srcdir)/po/LINGUAS; else echo "$(ALL_LINGUAS)"; fi)

USER_LINGUAS=$(shell if test -n "$(LINGUAS)"; then LLINGUAS="$(LINGUAS)"; ALINGUAS="$(ALL_LINGUAS)"; for lang in $$LLINGUAS; do if test -n "`grep \^$$lang$$ $(top_srcdir)/po/LINGUAS 2>/dev/null`" -o -n "`echo $$ALINGUAS|tr ' ' '\n'|grep \^$$lang$$`"; then printf "$$lang "; fi; done; fi)

USE_LINGUAS=$(shell if test -n "$(USER_LINGUAS)" -o -n "$(LINGUAS)"; then LLINGUAS="$(USER_LINGUAS)"; else if test -n "$(PO_LINGUAS)"; then LLINGUAS="$(PO_LINGUAS)"; else LLINGUAS="$(ALL_LINGUAS)"; fi; fi; for lang in $$LLINGUAS; do printf "$$lang "; done)

MAN_LINGUAS = C $(USE_LINGUAS)


PAGES = deja-dup.1 deja-dup-preferences.1

C/stamp: $(srcdir)/include.main $(srcdir)/include.pref $(top_builddir)/deja-dup/deja-dup $(top_builddir)/preferences/deja-dup-preferences
	@$(mkdir_p) C
	@$(srcdir)/help2man -N -i $(srcdir)/include.main -L en_US.UTF-8 $(top_builddir)/deja-dup/deja-dup > C/deja-dup.1
	@$(srcdir)/help2man -N -i $(srcdir)/include.pref -L en_US.UTF-8 $(top_builddir)/preferences/deja-dup-preferences > C/deja-dup-preferences.1
	$(AM_V_GEN)touch $@

%/stamp: $(top_builddir)/po/%.gmo $(srcdir)/include.main $(srcdir)/include.pref $(top_builddir)/deja-dup/deja-dup $(top_builddir)/preferences/deja-dup-preferences
	@$(mkdir_p) locales/$*/LC_MESSAGES
	@$(mkdir_p) $*
	@cp $(top_builddir)/po/$*.gmo locales/$*/LC_MESSAGES/deja-dup.mo
	@DEJA_DUP_LOCALEDIR=$(abs_builddir)/locales DEJA_DUP_LANGUAGE=$* $(srcdir)/help2man -N -i $(srcdir)/include.main -L en_US.UTF-8 $(top_builddir)/deja-dup/deja-dup > $*/deja-dup.1
	@DEJA_DUP_LOCALEDIR=$(abs_builddir)/locales DEJA_DUP_LANGUAGE=$* $(srcdir)/help2man -N -i $(srcdir)/include.pref -L en_US.UTF-8 $(top_builddir)/preferences/deja-dup-preferences > $*/deja-dup-preferences.1
	$(AM_V_GEN)touch $@

man: $(patsubst %,%/stamp,$(MAN_LINGUAS))

EXTRA_DIST = help2man include.main include.pref

clean-local: clean-local-@USE_NLS@
distclean-local: clean-local-@USE_NLS@
mostlyclean-local: clean-local-@USE_NLS@
maintainer-clean-local: clean-local-@USE_NLS@
clean-local-no:
clean-local-yes:
	rm -fr $(MAN_LINGUAS) locales

install-data-local: install-data-local-@USE_NLS@
install-data-local-no:
install-data-local-yes: man
	for lang in $(USE_LINGUAS); do \
		$(mkinstalldirs) "$(DESTDIR)$(mandir)/$$lang/man1"; \
		$(INSTALL_DATA) $$lang/*.1 "$(DESTDIR)$(mandir)/$$lang/man1"; \
	done
	$(mkinstalldirs) "$(DESTDIR)$(mandir)/man1"; \
	$(INSTALL_DATA) C/*.1 "$(DESTDIR)$(mandir)/man1";

uninstall-local: uninstall-local-@USE_NLS@
uninstall-local-no:
uninstall-local-yes: man
	for lang in $(USE_LINGUAS); do \
		for file in $(PAGES); do \
			rm -f "$(DESTDIR)$(mandir)/$$lang/man1/$$file"; \
		done \
	done
	for file in $(PAGES); do \
		rm -f "$(DESTDIR)$(mandir)/man1/$$file"; \
	done

dist-hook: man
