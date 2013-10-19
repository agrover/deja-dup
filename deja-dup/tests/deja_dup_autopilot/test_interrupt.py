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

import glob
import os
import shutil
from deja_dup_autopilot import DejaDupTestCase


class InterruptTests(DejaDupTestCase):

    def setUp(self):
        super(InterruptTests, self).setUp()
        self.point_at_data_playground()
        self.add_random_data('one', 30)

    def test_cancel(self):
        """Make sure we cancel correctly."""
        app = self.backup(waitfor='*.vol3.difftar.gpg')
        self.cancel(app)
        self.assertEqual([], os.listdir(self.backupdir))

    def test_resume(self):
        """Make sure we resume correctly."""
        app = self.backup(waitfor='*.vol3.difftar.gpg')
        self.resume(app)
        before = os.listdir(self.backupdir)
        self.assertGreaterEqual(len(before), 3)
        self.assertEqual(len(before), len(glob.glob(os.path.join(
            self.backupdir, '*.difftar.gpg'))))
        app = self.backup(first=False)
        self.assertIn(before[0], os.listdir(self.backupdir))
        self.assertEqual(1, len(glob.glob(os.path.join(
            self.backupdir, '*.vol1.difftar.gpg'))))
        self.assertEqual(1, len(glob.glob(os.path.join(
            self.backupdir, '*.manifest.gpg'))))

    def test_resume_noenc(self):
        """Make sure we resume correctly, without encryption."""
        app = self.backup(encrypted=False, waitfor='*.vol3.difftar.gz')
        self.resume(app)
        before = os.listdir(self.backupdir)
        self.assertGreaterEqual(len(before), 3)
        self.assertEqual(len(before), len(glob.glob(os.path.join(
            self.backupdir, '*.difftar.gz'))))
        app = self.backup(first=False, encrypted=False)
        self.assertIn(before[0], os.listdir(self.backupdir))
        self.assertEqual(1, len(glob.glob(os.path.join(
            self.backupdir, '*.vol1.difftar.gz'))))
        self.assertEqual(1, len(glob.glob(os.path.join(
            self.backupdir, '*.manifest'))))

    def test_resume_clean(self):
        """Make sure we clear out old files if we lose cache, in contrast
           to correct resume above."""
        app = self.backup(waitfor='*.vol3.difftar.gpg')
        self.resume(app)
        before = os.listdir(self.backupdir)
        self.assertGreaterEqual(len(before), 3)
        shutil.rmtree(os.path.join(self.rootdir, 'cache'))
        app = self.backup()
        self.assertNotIn(before[0], os.listdir(self.backupdir))
