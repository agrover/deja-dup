# -*- Mode: Python; indent-tabs-mode: nil; tab-width: 2; coding: utf-8 -*-
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
    self.backupdir = os.path.join(self.rootdir, 'backup')

    settings = Gio.Settings("org.gnome.DejaDup")
    settings.set_boolean("root-prompt", False)
    settings = Gio.Settings("org.gtk.Settings.FileChooser",
                            path="/org/gtk/settings/file-chooser/")
    settings.set_string("location-mode", "filename-entry")

  def point_at_data_playground(self):
    settings = Gio.Settings("org.gnome.DejaDup")
    settings.set_strv("include-list", [self.sourcedir])
    settings.set_string("backend", "file")
    settings = Gio.Settings("org.gnome.DejaDup.File")
    settings.set_string("path", self.backupdir)

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

  def backup(self):
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

  def iterate(self, p):
    print p, p.get_properties()
    for c in p.get_children():
      self.iterate(c)

  def restore(self):
    copydir = self.sourcedir + '.copy'
    os.rename(self.sourcedir, copydir)

    app = self.launch_test_application('deja-dup', '--restore')
    first_header_label = self.header_string('Restore From Where?')
    header = app.select_single('GtkLabel', label=first_header_label)
    button = app.select_single('GtkLabel', label='_Forward')
    self.pointer.click_object(button)

    self.assertThat(
      header.label,
      Eventually(Equals(self.header_string("Restore From When?"))))
    button = app.select_single('GtkLabel', label='_Forward')
    self.pointer.click_object(button)

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
      Eventually(Equals(self.header_string("Encryption Password Needed")),
                timeout=30))
    entry = app.select_single('GtkEntry', visible=True)
    with self.keyboard.focused_type(entry, pointer=self.pointer) as kb:
      kb.type("test")
    button = app.select_single('GtkLabel', label='Co_ntinue')
    self.pointer.click_object(button)

    self.assertThat(
      header.label,
      Eventually(Equals(self.header_string("Restore Finished")), timeout=30))
    button = app.select_single('GtkLabel', label='_Close')
    self.pointer.click_object(button)

    self.assertEqual(0, os.system('diff -ruN "%s" "%s"' % (copydir,
                                                           self.sourcedir)))
