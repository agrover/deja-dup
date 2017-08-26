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
  parse_one_dir("/backup/$USER", Path.build_filename("/backup", Environment.get_user_name()));
  parse_one_dir("backup/$USER", Path.build_filename(Environment.get_home_dir(), "backup", Environment.get_user_name()));
  parse_one_dir("$VIDEOS", Environment.get_user_special_dir(UserDirectory.VIDEOS));
  parse_one_dir("VIDEOS", Path.build_filename(Environment.get_home_dir(), "VIDEOS"));
  parse_one_dir("/VIDEOS", "/VIDEOS");
  parse_one_dir("file:///VIDEOS", "/VIDEOS");
  assert(DejaDup.parse_dir("file:VIDEOS").equal(File.parse_name("file:VIDEOS")));
}

void parse_one_version(string str, int maj, int min, int mic)
{
  int pmaj, pmin, pmic;
  assert(DejaDup.parse_version(str, out pmaj, out pmin, out pmic));
  assert(pmaj == maj);
  assert(pmin == min);
  assert(pmic == mic);
}

void parse_bad_version(string str)
{
  int pmaj, pmin, pmic;
  assert(!DejaDup.parse_version(str, out pmaj, out pmin, out pmic));
  assert(pmaj == 0);
  assert(pmin == 0);
  assert(pmic == 0);
}

void parse_version()
{
  parse_bad_version("");
  parse_one_version("a", 0, 0, 0);
  parse_one_version("1", 1, 0, 0);
  parse_one_version("1.2", 1, 2, 0);
  parse_one_version("1.2.3", 1, 2, 3);
  parse_one_version("1.2.3.4", 1, 2, 3);
  parse_one_version("1.2.3a4", 1, 2, 3);
  parse_one_version("1.2a3.4", 1, 2, 4);
  parse_one_version("1.2 3.4", 1, 2, 4);
  parse_one_version("1.2-3.4", 1, 2, 4);
}

void prompt()
{
  var settings = DejaDup.get_settings();

  settings.set_string(DejaDup.PROMPT_CHECK_KEY, "");
  DejaDup.update_prompt_time(true);
  assert(settings.get_string(DejaDup.PROMPT_CHECK_KEY) == "disabled");

  assert(DejaDup.make_prompt_check() == false);
  assert(settings.get_string(DejaDup.PROMPT_CHECK_KEY) == "disabled");
  DejaDup.update_prompt_time(); // shouldn't change anything
  assert(settings.get_string(DejaDup.PROMPT_CHECK_KEY) == "disabled");

  settings.set_string(DejaDup.PROMPT_CHECK_KEY, "");
  assert(DejaDup.make_prompt_check() == false);
  var time_now = settings.get_string(DejaDup.PROMPT_CHECK_KEY);
  assert(time_now != "");
  assert(DejaDup.make_prompt_check() == false);
  assert(settings.get_string(DejaDup.PROMPT_CHECK_KEY) == time_now);

  var cur_time = new DateTime.now_local();
  cur_time = cur_time.add_seconds(-1 * DejaDup.get_prompt_delay());
  cur_time = cur_time.add_hours(1);
  settings.set_string(DejaDup.PROMPT_CHECK_KEY, cur_time.format("%Y-%m-%dT%H:%M:%S%z"));
  assert(DejaDup.make_prompt_check() == false);

  cur_time = cur_time.add_hours(-2);
  settings.set_string(DejaDup.PROMPT_CHECK_KEY, cur_time.format("%Y-%m-%dT%H:%M:%S%z"));
  assert(DejaDup.make_prompt_check() == true);
}

// No backend change should happen
void migrate_file_s3()
{
  var settings = DejaDup.get_settings();
  var file = DejaDup.get_settings("File");

  settings.set_string(DejaDup.BACKEND_KEY, "s3");

  assert(!file.get_boolean("migrated"));
  DejaDup.initialize(null, null);

  assert(file.get_boolean("migrated"));
  assert(settings.get_string(DejaDup.BACKEND_KEY) == "s3");
}

void migrate_file_drive()
{
  var settings = DejaDup.get_settings();
  var file = DejaDup.get_settings("File");
  var drive = DejaDup.get_settings(DejaDup.DRIVE_ROOT);

  settings.set_string(DejaDup.BACKEND_KEY, "file");
  file.set_string("type", "volume");
  file.set_string("uuid", "uuid");
  file.set_string("icon", "icon");
  file.set_string("short-name", "short-name");
  file.set_string("name", "name");
  file.set_string("path", "file:///root");
  file.set_value("relpath", new Variant.bytestring("folder/path"));

  assert(!file.get_boolean("migrated"));
  DejaDup.initialize(null, null);

  assert(settings.get_string(DejaDup.BACKEND_KEY) == "drive");
  assert(file.get_boolean("migrated"));
  assert(drive.get_string(DejaDup.DRIVE_UUID_KEY) == "uuid");
  assert(drive.get_string(DejaDup.DRIVE_ICON_KEY) == "icon");
  assert(drive.get_string(DejaDup.DRIVE_NAME_KEY) == "short-name");
  assert(drive.get_string(DejaDup.DRIVE_FOLDER_KEY) == "folder/path");
}

void migrate_file_remote()
{
  var settings = DejaDup.get_settings();
  var file = DejaDup.get_settings("File");
  var remote = DejaDup.get_settings(DejaDup.REMOTE_ROOT);

  settings.set_string(DejaDup.BACKEND_KEY, "file");
  file.set_string("type", "normal");
  file.set_string("path", "resource://example.org/test/path"); // resource: is built into glib

  assert(!file.get_boolean("migrated"));
  DejaDup.initialize(null, null);

  assert(settings.get_string(DejaDup.BACKEND_KEY) == "remote");
  assert(file.get_boolean("migrated"));
  assert(remote.get_string(DejaDup.REMOTE_URI_KEY) == "resource:///example.org/test/path");
  assert(remote.get_string(DejaDup.REMOTE_FOLDER_KEY) == "");
}

void migrate_file_local()
{
  var settings = DejaDup.get_settings();
  var file = DejaDup.get_settings("File");
  var local = DejaDup.get_settings(DejaDup.LOCAL_ROOT);

  settings.set_string(DejaDup.BACKEND_KEY, "file");
  file.set_string("type", "normal");
  file.set_string("path", "file:///test/path");

  assert(!file.get_boolean("migrated"));
  DejaDup.initialize(null, null);

  assert(settings.get_string(DejaDup.BACKEND_KEY) == "local");
  assert(file.get_boolean("migrated"));
  assert(local.get_string(DejaDup.LOCAL_FOLDER_KEY) == "/test/path");
}

string get_top_builddir()
{
  var builddir = Environment.get_variable("top_builddir");
  if (builddir == null)
    builddir = Path.build_filename(get_top_srcdir(), "builddir");
  return builddir;
}

string get_top_srcdir()
{
  var srcdir = Environment.get_variable("top_srcdir");
  if (srcdir == null)
    srcdir = "../../..";
  return srcdir;
}

string get_srcdir()
{
  var srcdir = Environment.get_variable("srcdir");
  if (srcdir == null)
    srcdir = ".";
  return srcdir;
}

void setup()
{
}

void reset_keys(Settings settings)
{
  var source = SettingsSchemaSource.get_default();
  var schema = source.lookup(settings.schema_id, true);

  foreach (string key in schema.list_keys())
    settings.reset(key);

  foreach (string child in schema.list_children())
    reset_keys(settings.get_child(child));
}

void teardown()
{
  reset_keys(new Settings("org.gnome.DejaDup"));
}

int main(string[] args)
{
  Test.init(ref args);

  Environment.set_variable("PATH",
                           get_srcdir() + "/../mock:" +
                             Environment.get_variable("PATH"),
                           true);
  Environment.set_variable("DEJA_DUP_LANGUAGE", "en", true);
  Environment.set_variable("DEJA_DUP_TOOLS_PATH", Path.build_filename(get_top_builddir(), "libdeja/tools/duplicity"), true);
  Environment.set_variable("GSETTINGS_BACKEND", "memory", true);
  Test.bug_base("https://launchpad.net/bugs/%s");

  string tmpdir;
  try {
    tmpdir = DirUtils.make_tmp("deja-dup-test-XXXXXX");
  } catch (Error e) {
    printerr("Could not make temporary dir\n");
    return 1;
  }

  var schema_dir = Path.build_filename(tmpdir, "share", "glib-2.0", "schemas");
  DirUtils.create_with_parents(schema_dir, 0700);

  var data_dirs = Environment.get_variable("XDG_DATA_DIRS");
  Environment.set_variable("XDG_DATA_DIRS", "%s:%s".printf(Path.build_filename(tmpdir, "share"), data_dirs), true);

  if (Posix.system("cp %s/data/org.gnome.DejaDup.gschema.xml %s".printf(get_top_srcdir(), schema_dir)) != 0)
    warning("Could not copy schema to %s", schema_dir);

  if (Posix.system("glib-compile-schemas %s".printf(schema_dir)) != 0)
    warning("Could not compile schemas in %s", schema_dir);

  var unit = new TestSuite("unit");
  unit.add(new TestCase("migrate-file-drive", setup, migrate_file_drive, teardown));
  unit.add(new TestCase("migrate-file-local", setup, migrate_file_local, teardown));
  unit.add(new TestCase("migrate-file-remote", setup, migrate_file_remote, teardown));
  unit.add(new TestCase("migrate-file-s3", setup, migrate_file_s3, teardown));
  unit.add(new TestCase("parse-dir", setup, parse_dir, teardown));
  unit.add(new TestCase("parse-version", setup, parse_version, teardown));
  unit.add(new TestCase("prompt", setup, prompt, teardown));
  TestSuite.get_root().add_suite(unit);

  int rv = Test.run();

  if (Posix.system("rm -r --interactive=never %s".printf(tmpdir)) != 0)
    warning("Could not clean %s", tmpdir);

  return rv;
}   
