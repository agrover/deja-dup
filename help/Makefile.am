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
HELP_POT = deja-dup-help.pot
HELP_FILES = $(foreach f,$(shell ls $(srcdir)/C/*.page),$(shell basename $(f)))
HELP_LINGUAS = $(foreach f,$(shell ls $(srcdir)/*/*.po),$(shell basename $(f) .po))

DISTCLEANFILES = $(HELP_POT)
