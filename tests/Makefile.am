# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-

# This special name 'TESTS' will trigger an automatically-created 'check'
# target used during distcheck, for example.  This is nice.

TESTS = \
	basic/quit \
	basic/badversion \
	prefs/ssh-to-file
#	backup/local

test:
	@for t in $(TESTS); do \
		echo -n "Testing $$t..."; \
		if ./$$t >/dev/null 2>&1; then \
			echo -e " \e[32mPASSED\e[0m"; \
		else \
			echo -e " \e[31mFAILED\e[0m"; \
		fi; \
	done

EXTRA_DIST = $(TESTS) \
	base.py \
	basic/base.py \
	backup/base.py \
	prefs/base.py \
	build-duplicity \
	interactive \
	README

distclean-local:
	rm -rf duplicity duplicity-src
