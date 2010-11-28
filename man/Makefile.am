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

LINGUAS = C $(shell grep -v "^\#" $(top_srcdir)/po/LINGUAS)

C/stamp: include.main include.pref $(top_builddir)/deja-dup/deja-dup $(top_builddir)/preferences/deja-dup-preferences
	@$(mkdir_p) C
	@./help2man -N -i include.main -L en_US.UTF-8 $(top_builddir)/deja-dup/deja-dup > C/deja-dup.1
	@./help2man -N -i include.pref -L en_US.UTF-8 $(top_builddir)/preferences/deja-dup-preferences > C/deja-dup-preferences.1
	$(AM_V_GEN)touch $@

%/stamp: $(top_builddir)/po/%.gmo include.main include.pref $(top_builddir)/deja-dup/deja-dup $(top_builddir)/preferences/deja-dup-preferences
	@$(mkdir_p) locales/$*/LC_MESSAGES
	@$(mkdir_p) $*
	@cp $(top_builddir)/po/$*.gmo locales/$*/LC_MESSAGES/deja-dup.mo
	@DEJA_DUP_LOCALEDIR=$(abs_builddir)/locales DEJA_DUP_LANGUAGE=$* ./help2man -N -i include.main -L en_US.UTF-8 $(top_builddir)/deja-dup/deja-dup > $*/deja-dup.1
	@DEJA_DUP_LOCALEDIR=$(abs_builddir)/locales DEJA_DUP_LANGUAGE=$* ./help2man -N -i include.pref -L en_US.UTF-8 $(top_builddir)/preferences/deja-dup-preferences > $*/deja-dup-preferences.1
	$(AM_V_GEN)touch $@

man: $(patsubst %,%/stamp,$(LINGUAS))

clean-local: clean-local-@USE_NLS@
distclean-local: clean-local-@USE_NLS@
mostlyclean-local: clean-local-@USE_NLS@
maintainer-clean-local: clean-local-@USE_NLS@
clean-local-no:
clean-local-yes:
	rm -fr $(LINGUAS) locales

install-data-local: install-data-local-@USE_NLS@
install-data-local-no:
install-data-local-yes:
	for lang in $(LINGUAS); do \
		if [ -d $$lang ]; then \
			files=$$(ls $$lang/*.1); \
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
			files=$$(ls $$lang/*.1); \
			$(MAKE) uninstall-man \
				mandir="$(mandir)/$$lang" \
				man_MANS="" \
				dist_man1_MANS="$$files"; \
		fi \
	done

dist-hook: man
