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

# Don't use special name 'TESTS', as it will trigger an automatically-created
# 'check' target used during distcheck.

SUBDIRS = scripts unit runner

AUTO_TESTS = \
	backup/cancel \
	backup/cancel-clean \
	backup/clear-cache \
	backup/continue \
	backup/delete \
	backup/encrypt \
	backup/exclude \
	backup/mkdir \
	backup/quiescent \
	backup/spaces \
	backup/symlinks \
	restore/cycle \
	prefs/s3-folder \
	prefs/ssh-to-file \
	restore/full \
	restore/gpg \
	restore/missing \
	restore/rename \
	restore/overdir \
	restore/two

# Tests that must be run manually
# disk-full because it prompts for root password
MANUAL_TESTS = \
	backup/disk-full

ALL_TESTS = $(AUTO_TESTS) $(MANUAL_TESTS)

prep: data/symlink

data/symlink: $(srcdir)/data/symlink.tar.gz
	@echo "Expanding symlink.tar.gz"
	@rm -rf $(builddir)/data/symlink
	@mkdir -p $(builddir)/data
	@tar xf $(srcdir)/data/symlink.tar.gz -C $(builddir)/data

symtar:
	@echo "Making symlink.tar.gz"
	@rm -f $(builddir)/data/symlink.tar.gz
	@mkdir -p $(builddir)/data
	if [ -e $(srcdir)/data/symlink.tar.gz ]; then \
		cp $(srcdir)/data/symlink.tar.gz $(builddir)/data/symlink.tar.gz; \
	else \
		tar -cf $(builddir)/data/symlink.tar -C $(srcdir)/data symlink && gzip $(builddir)/data/symlink.tar; \
	fi
$(builddir)/data/symlink.tar.gz: symtar

# This is for 'interactive' running of all the tests.  See 'check' target for
# a target more suitable for automated testing.
test: prep
	rm -f test.log ; \
	for t in $(AUTO_TESTS); do \
		echo -n "Testing $$t..."; \
		if $(srcdir)/$$t >>test.log 2>&1; then \
			echo -e " \e[32mPASSED\e[0m"; \
		else \
			echo -e " \e[31mFAILED\e[0m"; \
		fi; \
	done; \
	for t in $(MANUAL_TESTS); do \
		echo -n "Testing $$t..."; \
		if $(srcdir)/$$t >>test.log 2>&1; then \
			echo -e " \e[32mPASSED\e[0m"; \
		else \
			echo -e " \e[31mFAILED\e[0m"; \
		fi; \
	done

# This is run automatically by distcheck and some build tools.
# Needs to error out if a test fails and needs to be runnable with no DISPLAY.
# Use system duplicity to avoid downloading on the fly and to facilitate
# testing against a distro's potentially patched version of duplicity.
XXXcheck: prep
	@export TESTS_PASSED=true ; \
	export DEJA_DUP_TEST_VERSION=system ; \
	export DISPLAY= ; \
	export srcdir=$(srcdir) ; \
	export distdir=$(distdir) ; \
	export builddir=$(builddir) ; \
	for t in $(AUTO_TESTS); do \
		echo -n "Testing $$t..."; \
		if ! $(srcdir)/wrap $(srcdir)/$$t; then \
			export TESTS_PASSED=false ; \
		fi; \
	done; \
	$${TESTS_PASSED}

EXTRA_DIST = \
	backup \
	prefs \
	restore \
	base.py \
	build-duplicity \
	interactive \
	wrap \
	data \
	vols \
	README

distclean-local:
	rm -rf duplicity duplicity-src
	rm -f data/symlink.tar.gz
	rm -rf $(builddir)/data/symlink
	rm -f test.log

dist-hook: symtar
	@rm -rf $(distdir)/data/symlink
	if ! [ -e $(distdir)/data/symlink.tar.gz ]; then \
		mkdir -p $(distdir)/data; \
		cp -p $(builddir)/data/symlink.tar.gz $(distdir)/data; \
	fi
