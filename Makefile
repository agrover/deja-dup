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

all: configure
	ninja -C builddir

%:
	@[ "$@" = "Makefile" ] || ninja -C builddir $@

configure:
	@[ -f builddir/build.ninja ] || meson -Dprofile=Devel builddir

distconfigure:
	@[ -f builddir/build.ninja ] || meson builddir

check: all
	LC_ALL=C.UTF-8 meson test -C builddir

dist: clean distconfigure screenshots pot
	rm -f builddir/meson-dist/*
	ninja -C builddir dist
	gpg --armor --sign --detach-sig builddir/meson-dist/deja-dup-*.tar.xz

clean distclean:
	rm -rf builddir

deb:
	DEB_BUILD_OPTIONS=nocheck debuild

screenshots: all
	@gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
	@gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
	@gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
	@gsettings set org.gnome.desktop.wm.preferences theme 'Adwaita'
	@gsettings set org.gnome.DejaDup backend 'file'
	@sleep 5
	
	@mkdir -p ./builddir/screenshots
	@rm -f ./builddir/screenshots/*
	
	@./tests/shell-local "deja-dup" &
	@gnome-screenshot --window --delay 1 --file data/appdata/01-main.png
	@killall deja-dup
	
	@./tests/shell-local "deja-dup --backup" >/dev/null &
	@gnome-screenshot --window --delay 1 --file data/appdata/02-backup.png
	@killall deja-dup
	
	@gsettings reset org.gnome.desktop.interface font-name
	@gsettings reset org.gnome.desktop.interface gtk-theme
	@gsettings reset org.gnome.desktop.interface icon-theme
	@gsettings reset org.gnome.desktop.wm.preferences theme
	@gsettings reset org.gnome.DejaDup backend
	
	@eog data/appdata

pot: configure
	ninja -C builddir deja-dup-pot help-org.gnome.DejaDup-pot

# call like 'make copy-po TD=path-to-translation-dir'
copy-po:
	test -d $(TD)
	cp -a $(TD)/po/*.po po
	for po in $(TD)/deja-dup/help/*.po; do \
		mkdir -p deja-dup/help/$$(basename $$po .po); \
		cp -a $$po deja-dup/help/$$(basename $$po .po)/; \
	done
	git add po/*.po
	git add deja-dup/help/*/*.po

flatpak:
	flatpak-builder --repo=$(HOME)/repo \
	                --force-clean \
	                --state-dir=builddir/.flatpak-builder \
	                builddir/flatpak \
	                flatpak/org.gnome.DejaDupDevel.yaml
	flatpak update --user -y org.gnome.DejaDupDevel

.PHONY: configure distconfigure clean dist all copy-po check screenshots flatpak
