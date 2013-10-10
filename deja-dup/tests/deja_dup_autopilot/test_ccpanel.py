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
from autopilot.matchers import Eventually
from deja_dup_autopilot import DejaDupTestCase, system_only
from testtools.matchers import Equals, NotEquals


class CCPanelTests(DejaDupTestCase):

    @system_only
    def setUp(self):
        super(CCPanelTests, self).setUp()
        if os.environ.get("HAS_CCPANEL") != "1":
            self.skip("Skipping disabled ccpanel test")

    def test_clean_exit(self):
        """Launch and close the panel a couple times.  If we don't properly
           clean up after ourselves when we are disposed, this may cause a
           crash."""
        app = self.launch_test_application('gnome-control-center', 'deja-dup')
        window = app.select_single("GtkApplicationWindow")
        self.assertThat(window.title, Eventually(Equals("Backups")))
        self.close_backup_panel(window)
        self.open_backup_panel(window)
        self.close_backup_panel(window)

    def open_backup_panel(self, window):
        # This is dumb, but GtkIconView doesn't seem to list its contents to
        # autopilot.  TODO: make this actually click on Backup icon in window
        os.system('gnome-control-center deja-dup')
        self.assertThat(window.title, Eventually(Equals("Backups")))

    def close_backup_panel(self, window):
        button = window.select_single("GtkButton", label="_All Settings")
        self.pointer.click_object(button)
        self.assertThat(window.title, Eventually(NotEquals("Backups")))
