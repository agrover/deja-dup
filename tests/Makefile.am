# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-

BASE_FILES = \
	base.py

TESTS = \
	local-backup

test:
	@for t in $(TESTS); do \
		echo -n "Testing $$t..."; \
		if ./$$t  2>/dev/null; then \
			echo " PASSED"; \
		else \
			echo " FAIL"; \
		fi; \
	done

EXTRA_DIST = $(TESTS) $(BASE_FILES) data

