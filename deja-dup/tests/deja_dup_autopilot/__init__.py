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
import subprocess
from autopilot.input import Pointer, Touch
from autopilot.matchers import Eventually
from autopilot.testcase import AutopilotTestCase
from functools import wraps
from gi.repository import Gio
from testtools.matchers import Equals


def system_only(fn):
    """A simple decorator that skips test if we are in local mode."""
    @wraps(fn)
    def wrapper(*args, **kwargs):
        if os.environ.get('DEJA_DUP_TEST_SYSTEM') != '1':
            tests_self = args[0]
            tests_self.skip("Skipping system test")
        return fn(*args, **kwargs)
    return wrapper


class DejaDupTestCase(AutopilotTestCase):
    """A test case base class for the Unity shell tests."""

    def setUp(self):
        super(DejaDupTestCase, self).setUp()
        self.pointer = Pointer(Touch.create())

        self.rootdir = os.environ['DEJA_DUP_TEST_ROOT']
        self.sourcedir = os.path.join(self.rootdir, 'source')
        self.copydir = os.path.join(self.rootdir, 'source.copy')
        self.backupdir = os.path.join(self.rootdir, 'backup')
        self.addCleanup(shutil.rmtree, self.sourcedir)
        self.addCleanup(shutil.rmtree, self.copydir)
        self.addCleanup(shutil.rmtree, self.backupdir)
        self.addCleanup(shutil.rmtree, os.path.join(self.rootdir, 'cache'))
        try:
            os.makedirs(self.sourcedir)
        except OSError:
            pass

        self.set_config("root-prompt", False)
        self.set_config("location-mode", "filename-entry",
                        schema="org.gtk.Settings.FileChooser",
                        path="/org/gtk/settings/file-chooser/")

        # And a catch-all for the other settings that get set as part of a
        # deja-dup run, like last-backup or such.
        self.addCleanup(os.system,
                        "gsettings reset-recursively org.gnome.DejaDup")

    def set_config(self, key, value, schema="org.gnome.DejaDup", path=None):
        settings = Gio.Settings(schema, path=path)
        if type(value) is list:
            settings.set_strv(key, value)
        elif type(value) is bool:
            settings.set_boolean(key, value)
        elif type(value) is str:
            settings.set_string(key, value)
        else:
            settings.set_value(key, value)
        self.addCleanup(settings.reset, key)

    def iterate(self, p):
        "Not meant for production use, just a debugging tool"
        print p, p.get_properties()
        for c in p.get_children():
            self.iterate(c)

    def point_at_data_playground(self):
        self.set_config("include-list", [self.sourcedir])
        self.set_config("backend", "file")
        self.set_config("path", self.backupdir,
                        schema="org.gnome.DejaDup.File")

    def add_simple_data(self):
        """Just put some really simple data in the backup source."""
        with open(os.path.join(self.sourcedir, 'one'), 'w') as f:
            f.write('one')
        with open(os.path.join(self.sourcedir, 'two'), 'w') as f:
            f.write('two')
        with open(os.path.join(self.sourcedir, 'three'), 'w') as f:
            f.write('three')
        subdir = os.path.join(self.sourcedir, 'subdir')
        os.mkdir(subdir)
        with open(os.path.join(subdir, 'one'), 'w') as f:
            f.write('one')
        deeper = os.path.join(subdir, 'deeper')
        os.mkdir(deeper)

    def use_simple_setup(self):
        self.point_at_data_playground()
        self.add_simple_data()

    def header_string(self, label):
        return '<span size="xx-large" weight="ultrabold">%s</span>' % label

    def backup(self, gui=True):
        if not gui:
            # Sometimes we just want the backup to exist, without testing the
            # gui workflow itself.  Note that this puts the archive files in
            # a place where deja-dup won't find them.  Do we want that?
            p = subprocess.Popen(['env', 'PASSPHRASE=test', 'duplicity', '/',
                                  '--include=' + self.sourcedir,
                                  '--exclude=**', 'file://' + self.backupdir],
                                 stdout=subprocess.PIPE)
            p.communicate()
            self.assertEqual(0, p.returncode)
            return

        app = self.launch_test_application('deja-dup', '--backup')
        first_header_label = self.header_string(u'Backing Up…')
        header = app.select_single('GtkLabel', label=first_header_label)

        self.assertThat(
            header.label,
            Eventually(Equals(self.header_string("Require Password?"))))
        entries = app.select_many('GtkEntry', visible=True)
        self.assertEquals(len(entries), 2)
        for entry in entries:
            with self.keyboard.focused_type(entry, pointer=self.pointer) as kb:
                kb.type("test")
        button = app.select_single('GtkLabel', label='Co_ntinue')
        self.pointer.click_object(button)

        self.assertThat(app.process.poll, Eventually(Equals(0), timeout=30))

    def copy_sourcedir(self, delete=True):
        if delete:
            shutil.move(self.sourcedir, self.copydir)
        else:
            shutil.copytree(self.sourcedir, self.copydir, symlinks=True)

    def restore(self, files=[]):
        app = self.launch_test_application('deja-dup', '--restore', *files)
        first_header_label = self.header_string('Restore From Where?')
        header = app.select_single('GtkLabel', label=first_header_label)
        button = app.select_single('GtkLabel', label='_Forward')
        self.pointer.click_object(button)

        self.assertThat(
            header.label,
            Eventually(Equals(self.header_string("Restore From When?"))))
        button = app.select_single('GtkLabel', label='_Forward')
        self.pointer.click_object(button)

        if not files:
            self.assertThat(
                header.label,
                Eventually(Equals(self.header_string("Restore to Where?"))))
            button = app.select_single('GtkLabel', label='_Forward')
            self.pointer.click_object(button)

        self.assertThat(
            header.label,
            Eventually(Equals(self.header_string("Summary"))))
        button = app.select_single('GtkLabel', label='_Restore')
        self.pointer.click_object(button)

        self.assertThat(
            header.label,
            Eventually(
                Equals(self.header_string("Encryption Password Needed")),
                timeout=30))
        entry = app.select_single('GtkEntry', visible=True)
        with self.keyboard.focused_type(entry, pointer=self.pointer) as kb:
            kb.type("test")
        button = app.select_single('GtkLabel', label='Co_ntinue')
        self.pointer.click_object(button)

        self.assertThat(
            header.label,
            Eventually(Equals(self.header_string("Restore Finished")),
                       timeout=30))
        button = app.select_single('GtkLabel', label='_Close')
        self.pointer.click_object(button)

    def restore_missing(self, path, files):
        self.assertNotEqual(len(files), 0)

        app = self.launch_test_application('deja-dup', '--restore-missing',
                                           path)
        first_header_label = self.header_string('Restore From Where?')
        header = app.select_single('GtkLabel', label=first_header_label)
        button = app.select_single('GtkLabel', label='_Forward')
        self.pointer.click_object(button)

        self.assertThat(
            header.label,
            Eventually(
                Equals(self.header_string("Encryption Password Needed")),
                timeout=30))
        entry = app.select_single('GtkEntry', visible=True)
        with self.keyboard.focused_type(entry, pointer=self.pointer) as kb:
            kb.type("test")
        button = app.select_single('GtkLabel', label='Co_ntinue')
        self.pointer.click_object(button)

        label = app.select_single('GtkLabel', BuilderName='status-label')
        self.assertThat(label.label, Eventually(Equals("Scanning finished")))

        tree = app.select_single('GtkTreeViewAccessible')
        checkboxes = tree.select_many('GtkBooleanCellAccessible')
        labels = tree.select_many('GtkTextCellAccessible')
        for i in range(len(checkboxes)):
            # Multiply by two, because there are two labels for each checkbox.
            # The first is the name, the second is the date.
            if labels[i * 2].accessible_name in files:
                self.pointer.click_object(checkboxes[i])
        button = app.select_single('GtkLabel', label='_Forward')
        self.pointer.click_object(button)

        self.assertThat(
            header.label,
            Eventually(Equals(self.header_string("Summary"))))
        button = app.select_single('GtkLabel', label='_Restore')
        self.pointer.click_object(button)

        self.assertThat(
            header.label,
            Eventually(
                Equals(self.header_string("Encryption Password Needed")),
                timeout=30))
        # No need to enter text, it should be saved from before
        button = app.select_single('GtkLabel', label='Co_ntinue')
        self.pointer.click_object(button)

        self.assertThat(
            header.label,
            Eventually(Equals(self.header_string("Restore Finished")),
                       timeout=300000))
        button = app.select_single('GtkLabel', label='_Close')
        self.pointer.click_object(button)

    def compare(self, equal=None, missing=[]):
        if equal is None:
            self.assertEqual(
                0, os.system('diff -ruN "%s" "%s"' % (self.copydir,
                                                      self.sourcedir)))
            return

        for e in equal:
            copy = os.path.join(self.copydir, e)
            source = os.path.join(self.sourcedir, e)
            self.assertEqual(
                0, os.system('diff -ruN "%s" "%s"' % (copy, source)))

        for m in missing:
            source = os.path.join(self.sourcedir, m)
            self.assertEqual(False, os.path.exists(source))
