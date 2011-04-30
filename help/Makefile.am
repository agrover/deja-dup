# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# © 2008,2009,2010,2011 Michael Terry <mike@mterry.name>
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

include $(top_srcdir)/gnome-doc-utils.make

DOC_ID = deja-dup

DOC_PAGES = \
	backup-auto.page \
	backup-first.page \
	credits.page \
	contribute.page \
	index.page \
	license.page \
	prefs.page \
	restore-full.page \
	restore-lost.page \
	restore-revert.page \
	restore-worst-case.page \
	support.page

REAL_LINGUAS = ar cs da de en_GB es eu fi fr gl he hu id it ja lt nb nl pl ps pt_BR ru sv th tr zh_CN
DOC_LINGUAS = POT $(REAL_LINGUAS)

$(_DOC_LC_DOCS) : po.stamp

po.stamp: $(wildcard translations/*.po)
	for p in $?; do $(mkdir_p) $$(basename $$p .po)/; \
	                cp -a $$p $$(basename $$p .po)/; done
	touch $@

update-pot: translations/deja-dup-help.pot
POT/POT.po: $(foreach page,$(DOC_PAGES),C/$(page))
translations/deja-dup-help.pot: POT/POT.po
	$(mkdir_p) $(dir $@)
	sed 's|^#: /.*/\(.*\)|#: \1|g' $^ > $@

dist-hook: doc-dist-hook
	for p in $(REAL_LINGUAS); do \
		sed -i "s|<list><title>.*</title><item><p>translator-credits</p></item></list>||" "$(distdir)/$$p/credits.page"; \
		sed -i "s|<screen>deja-dup|<screen>$(pkglibexecdir)/deja-dup|g" "$(distdir)/$$p/"*.page; \
	done

EXTRA_DIST = translations po.stamp
DISTCLEANFILES = translations/deja-dup-help.pot

.PHONY: update-pot
