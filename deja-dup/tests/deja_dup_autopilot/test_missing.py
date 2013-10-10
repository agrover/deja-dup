# -*- Mode: Python; indent-tabs-mode: nil; tab-width: 4; coding: utf-8 -*-
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

import os
import shutil
from deja_dup_autopilot import DejaDupTestCase


class MissingTests(DejaDupTestCase):

    def test_missing(self):
        """Test missing files workflow"""
        self.use_simple_setup()
        self.backup(gui=False)

        self.copy_sourcedir()
        os.mkdir(self.sourcedir)
        shutil.copy2(os.path.join(self.copydir, 'three'), self.sourcedir)

        self.restore_missing(self.sourcedir, ['one', 'subdir'])
        self.compare(equal=['one', 'three', 'subdir'], missing=['two'])
