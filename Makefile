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

all: builddir
	make -C builddir all

%:
	@[ "$@" = "Makefile" ] || make -C builddir $@

builddir:
	@[ -d builddir ] || ( mkdir builddir && cd builddir && cmake .. -DCMAKE_BUILD_TYPE=Debug )

check: all
	CTEST_OUTPUT_ON_FAILURE=1 make -C builddir test

check-system: all
	CTEST_OUTPUT_ON_FAILURE=1 make -C builddir test-system

dist: builddir screenshots
	rm -f builddir/deja-dup-*.tar*
	make -C builddir deja-dup.pot deja-dup-help.pot package_source
	# Need the following until CPack supports an xz generator
	bunzip2 builddir/deja-dup-*.tar.bz2
	xz builddir/deja-dup-*.tar
	gpg --armor --sign --detach-sig builddir/deja-dup-*.tar.xz

clean:
	rm -rf builddir obj-*

deb:
	DEB_BUILD_OPTIONS=nocheck debuild

screenshots: all
	@mkdir -p ./builddir/screenshots
	@rm -f ./builddir/screenshots/*
	@./tests/shell "gsettings set org.gnome.DejaDup backend 'file';" \
	               "gsettings set org.gnome.DejaDup.File icon 'drive-removable-media';" \
	               "gsettings set org.gnome.DejaDup.File short-name 'Backup Drive';" \
	               "gsettings set org.gnome.DejaDup.File uuid 'NOPE';" \
	               "gsettings set org.gnome.DejaDup.File type 'volume';" \
	               "gsettings set org.gnome.DejaDup.File path '/NOPE';" \
	               "env HOME=/NOPE deja-dup-preferences" >/dev/null 2>&1 &
	@gnome-screenshot --window --delay 1 --file ./builddir/screenshots/screenshot-1.jpg
	@killall deja-dup-preferences
	@./tests/shell "deja-dup --backup" >/dev/null &
	@gnome-screenshot --window --delay 1 --file ./builddir/screenshots/screenshot-2.jpg
	@killall deja-dup

# call like 'make copy-po TD=path-to-translation-dir'
copy-po:
	test -d $(TD)
	cp -a $(TD)/po/*.po po
	for po in $(TD)/deja-dup/help/*.po; do \
		mkdir -p deja-dup/help/$$(basename $$po .po); \
		cp -a $$po deja-dup/help/$$(basename $$po .po)/; \
	done
	bzr add po/*.po
	bzr add deja-dup/help/*/*.po

.PHONY: builddir clean dist all copy-po check check-system screenshots
