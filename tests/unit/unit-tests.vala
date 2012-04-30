// -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2; coding: utf-8 -*-
/*
    This file is part of Déjà Dup.
    For copyright information, see AUTHORS.

    Déjà Dup is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Déjà Dup is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Déjà Dup.  If not, see <http://www.gnu.org/licenses/>.
*/

using GLib;

void parse_one_dir (string to_parse, string? result)
{
  if (result != null)
    assert(DejaDup.parse_dir(to_parse).equal(File.new_for_path(result)));
}

void parse_dir()
{
  parse_one_dir("", Environment.get_home_dir());
  parse_one_dir("$HOME", Environment.get_home_dir());
  parse_one_dir("$TRASH", Path.build_filename(Environment.get_user_data_dir(), "Trash"));
  parse_one_dir("$DESKTOP", Environment.get_user_special_dir(UserDirectory.DESKTOP));
  parse_one_dir("$DOCUMENTS", Environment.get_user_special_dir(UserDirectory.DOCUMENTS));
  parse_one_dir("$DOWNLOAD", Environment.get_user_special_dir(UserDirectory.DOWNLOAD));
  parse_one_dir("$MUSIC", Environment.get_user_special_dir(UserDirectory.MUSIC));
  parse_one_dir("$PICTURES", Environment.get_user_special_dir(UserDirectory.PICTURES));
  parse_one_dir("$PUBLIC_SHARE", Environment.get_user_special_dir(UserDirectory.PUBLIC_SHARE));
  parse_one_dir("$TEMPLATES", Environment.get_user_special_dir(UserDirectory.TEMPLATES));
  parse_one_dir("$VIDEOS", Environment.get_user_special_dir(UserDirectory.VIDEOS));
  parse_one_dir("VIDEOS", Path.build_filename(Environment.get_home_dir(), "VIDEOS"));
  parse_one_dir("/VIDEOS", "/VIDEOS");
  parse_one_dir("file:///VIDEOS", "/VIDEOS");
  assert(DejaDup.parse_dir("file:VIDEOS").equal(File.parse_name("file:VIDEOS")));
}

void setup()
{
}

void teardown()
{
}

int main(string[] args)
{
  Test.init(ref args);

  Environment.set_variable("DEJA_DUP_LANGUAGE", "en", true);
  Environment.set_variable("GSETTINGS_BACKEND", "memory", true);
  Test.bug_base("https://launchpad.net/bugs/%s");

  var unit = new TestSuite("unit");
  unit.add(new TestCase("parse-dir", setup, parse_dir, teardown));
  TestSuite.get_root().add_suite(unit);

  return Test.run();
}
