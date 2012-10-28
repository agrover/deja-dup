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
	backup/continue \
	backup/delete \
	backup/encrypt \
	backup/quiescent \
	restore/cycle \
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

# This is for 'interactive' running of all the tests.  See 'check' target for
# a target more suitable for automated testing.
test:
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

EXTRA_DIST = \
	backup \
	restore \
	base.py \
	build-duplicity \
	interactive \
	data \
	vols \
	README

distclean-local:
	rm -rf duplicity duplicity-src
	rm -f test.log
