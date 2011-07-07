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

@YELP_HELP_RULES@

HELP_ID = deja-dup

HELP_FILES = \
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

HELP_LINGUAS = ar cs da de en_GB es eu fi fr gl he hr hu id it ja lt nb nl pl ps pt_BR ru sv th tr zh_CN zh_TW

deja-dup-help.pot: deja-dup.pot
	cp -a $^ $@

pot: deja-dup-help.pot
all: deja-dup-help.pot
