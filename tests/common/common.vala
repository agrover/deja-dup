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

void testing_mode()
{
  Environment.unset_variable("DEJA_DUP_TESTING");
  assert(!DejaDup.in_testing_mode());
  Environment.set_variable("DEJA_DUP_TESTING", "0", true);
  assert(!DejaDup.in_testing_mode());
  Environment.set_variable("DEJA_DUP_TESTING", "1", true);
  assert(DejaDup.in_testing_mode());
  Environment.unset_variable("DEJA_DUP_TESTING");
}

void get_day()
{
  Environment.unset_variable("DEJA_DUP_TESTING");
  assert(DejaDup.get_day() == TimeSpan.DAY);
  Environment.set_variable("DEJA_DUP_TESTING", "1", true);
  assert(DejaDup.get_day() == TimeSpan.SECOND * (TimeSpan)10);
  Environment.unset_variable("DEJA_DUP_TESTING");
}

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

void parse_dir_list()
{
  
}

void mode_to_string()
{
  assert(DejaDup.Operation.mode_to_string(DejaDup.Operation.Mode.INVALID) == "Preparing…");
  assert(DejaDup.Operation.mode_to_string(DejaDup.Operation.Mode.BACKUP) == "Backing up…");
  assert(DejaDup.Operation.mode_to_string(DejaDup.Operation.Mode.RESTORE) == "Restoring…");
  assert(DejaDup.Operation.mode_to_string(DejaDup.Operation.Mode.STATUS) == "Checking for backups…");
  assert(DejaDup.Operation.mode_to_string(DejaDup.Operation.Mode.LIST) == "Listing files…");
  assert(DejaDup.Operation.mode_to_string(DejaDup.Operation.Mode.FILEHISTORY) == "Preparing…");
}

void backup_setup()
{
  var dir = Environment.get_variable("DEJA_DUP_TEST_HOME");

  var cachedir = Path.build_filename(dir, "cache");
  DirUtils.create_with_parents(Path.build_filename(cachedir, "deja-dup"), 0700);

  Environment.set_variable("DEJA_DUP_TEST_MOCKSCRIPT", Path.build_filename(dir, "mockscript"), true);
  Environment.set_variable("XDG_CACHE_HOME", cachedir, true);
  Environment.set_variable("PATH", "./mock:" + Environment.get_variable("PATH"), true);

  var settings = DejaDup.get_settings();
  settings.set_string(DejaDup.BACKEND_KEY, "file");
  settings = DejaDup.get_settings(DejaDup.FILE_ROOT);
  settings.set_string(DejaDup.FILE_PATH_KEY, "/tmp/not/a/thing");
}

void backup_teardown()
{
  var path = Environment.get_variable("PATH");
  if (path.has_prefix("./mock:")) {
    path = path.substring(7);
    Environment.set_variable("PATH", path, true);
  }

  var file = File.new_for_path(Environment.get_variable("DEJA_DUP_TEST_MOCKSCRIPT"));
  if (file.query_exists(null)) {
    // Fail the test, something went wrong
    warning("Mockscript file still exists");
  }

  file = File.new_for_path("/tmp/not/a/thing");
  if (file.query_exists(null)) {
    try {
      file.delete(null);
    }
    catch (Error e) {
      assert_not_reached();
    }
  }

  if (Posix.system("rm -r %s".printf(Environment.get_variable("DEJA_DUP_TEST_HOME"))) != 0)
    warning("Could not clean TEST_HOME %s", Environment.get_variable("DEJA_DUP_TEST_HOME"));

  Environment.unset_variable("DEJA_DUP_TEST_MOCKSCRIPT");
  Environment.unset_variable("XDG_CACHE_HOME");
}

public void set_script(string contents)
{
  try {
    var script = Environment.get_variable("DEJA_DUP_TEST_MOCKSCRIPT");
    FileUtils.set_contents(script, contents);
  }
  catch (Error e) {
    assert_not_reached();
  }
}

public enum Mode {
  NONE,
  DRY,
  BACKUP,
  CLEANUP,
  RESTORE,
  RESTORE_STATUS,
  LIST,
}

public string default_args(Mode mode = Mode.NONE, bool encrypted = false, string extra = "")
{
  var cachedir = Environment.get_variable("XDG_CACHE_HOME");

  if (mode == Mode.CLEANUP)
    return "'--force' 'file:///tmp/not/a/thing' '--gio' '--no-encryption' '--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=%s/deja-dup' '--log-fd=?'".printf(cachedir);
  else if (mode == Mode.RESTORE)
    return "'restore' '--gio' '--force' 'file:///tmp/not/a/thing' '/tmp/not/a/restore' '--no-encryption' '--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=%s/deja-dup' '--log-fd=?'".printf(cachedir);
  else if (mode == Mode.LIST)
    return "'list-current-files' '--gio' 'file:///tmp/not/a/thing' '--no-encryption' '--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=%s/deja-dup' '--log-fd=?'".printf(cachedir);

  string source_str = "";
  if (mode == Mode.DRY || mode == Mode.BACKUP)
    source_str = "--volsize=50 / ";

  string dry_str = "";
  if (mode == Mode.DRY)
    dry_str = "--dry-run ";

  string enc_str = "";
  if (!encrypted)
    enc_str = "--no-encryption ";

  string args = "";

  if (mode == Mode.NONE || mode == Mode.DRY || mode == Mode.BACKUP) {
    args += "'--exclude=/tmp/not/a/thing' ";

    string[] excludes1 = {"~/Downloads", "~/.local/share/Trash", "~/.xsession-errors", "~/.thumbnails", "~/.Private", "~/.gvfs", "~/.adobe/Flash_Player/AssetCache"};

    var user = Environment.get_user_name();
    string[] excludes2 = {"/home/.ecryptfs/%s/.Private".printf(user), "/sys", "/proc", "/tmp"};

    foreach (string ex in excludes1) {
      ex = ex.replace("~", Environment.get_home_dir());
      if (FileUtils.test (ex, FileTest.EXISTS))
        args += "'--exclude=%s' ".printf(ex);
    }

    args += "'--include=%s' ".printf(Environment.get_home_dir());

    foreach (string ex in excludes2) {
      ex = ex.replace("~", Environment.get_home_dir());
      if (FileUtils.test (ex, FileTest.EXISTS))
        args += "'--exclude=%s' ".printf(ex);
    }

    args += "'--exclude=%s/deja-dup' '--exclude=%s' '--exclude=**' ".printf(cachedir, cachedir);
  }

  args += "%s%s'--gio' %s'file:///tmp/not/a/thing' %s'--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=%s/deja-dup' '--log-fd=?'".printf(extra, dry_str, source_str, enc_str, cachedir);

  return args;
}

TestCase make_backup_case(string name, TestFunc cb)
{
  return new TestCase(name, backup_setup, cb, backup_teardown);
}

class RestoreRunner : Object
{
  public delegate void OpCallback (DejaDup.Operation op);
  public bool success = true;
  public bool cancelled = false;
  public string? detail = null;
  public string? error_str = null;
  public string? error_detail = null;
  public OpCallback? callback = null;

  public void run()
  {
    var loop = new MainLoop(null);
    var op = new DejaDup.OperationRestore("/tmp/not/a/restore");
    op.done.connect((op, s, c, d) => {
      Test.message("Done: %d, %d, %s", (int)s, (int)c, d);
      if (success != s)
        warning("Success didn't match; expected %d, got %d", (int) success, (int) s);
      if (cancelled != c)
        warning("Cancel didn't match; expected %d, got %d", (int) cancelled, (int) c);
      if (detail != d)
        warning("Detail didn't match; expected %s, got %s", detail, d);
      loop.quit();
    });

    op.raise_error.connect((str, det) => {
      Test.message("Error: %s, %s", str, det);
      if (error_str != str)
        warning("Error string didn't match; expected %s, got %s", error_str, str);
      if (error_detail != det)
        warning("Error detail didn't match; expected %s, got %s", error_detail, det);
      error_str = null;
      error_detail = null;
    });
    op.action_desc_changed.connect((action) => {
    });
    op.action_file_changed.connect((file, actual) => {
    });
    op.progress.connect((percent) => {
    });
    op.passphrase_required.connect(() => {
      Test.message("Passphrase required");
    });
    op.question.connect((title, msg) => {
      Test.message("Question asked: %s, %s", title, msg);
    });
    op.is_full.connect((full) => {
      warning("Didn't expect IsFull");
    });

    op.start();
    if (callback != null) {
      Timeout.add_seconds(3, () => {
        callback(op);
        return false;
      });
    }
    loop.run();

    if (error_str != null)
      warning("Error str didn't match; expected %s, never got error", error_str);
    if (error_detail != null)
      warning("Error detail didn't match; expected %s, never got error", error_detail);
  }
}

void write_error()
{
  var home = Environment.get_home_dir();
  set_script("""
ARGS: collection-status %s

=== deja-dup ===
ARGS: %s

=== deja-dup ===
ARGS: %s

WARNING 12 '/blarg'
. [Errno 1] not a real error

WARNING 12 '%s/1'
. [Errno 13] real error

WARNING 12 '%s/2'
. [Errno 13] real error

""".printf(default_args(Mode.RESTORE_STATUS),
           default_args(Mode.LIST),
           default_args(Mode.RESTORE), home, home));

  var br = new RestoreRunner();
  br.detail = """Could not restore the following files.  Please make sure you are able to write to them.

%s/1
%s/2""".printf(home, home);
  br.run();
}

void setup_gsettings()
{
  var dir = Environment.get_variable("DEJA_DUP_TEST_HOME");

  var schema_dir = Path.build_filename(dir, "share", "glib-2.0", "schemas");
  DirUtils.create_with_parents(schema_dir, 0700);

  var data_dirs = Environment.get_variable("XDG_DATA_DIRS");
  Environment.set_variable("XDG_DATA_DIRS", "%s:%s".printf(Path.build_filename(dir, "share"), data_dirs), true);

  if (Posix.system("cp ../../data/org.gnome.DejaDup.gschema.xml %s".printf(schema_dir)) != 0)
    warning("Could not copy schema to %s", schema_dir);

  if (Posix.system("glib-compile-schemas %s".printf(schema_dir)) != 0)
    warning("Could not compile schemas in %s", schema_dir);

  Environment.set_variable("GSETTINGS_BACKEND", "memory", true);
}

int main(string[] args)
{
  Test.init(ref args);

  var dir = "/tmp/deja-dup-test-XXXXXX";
  dir = DirUtils.mkdtemp(dir);
  Environment.set_variable("DEJA_DUP_TEST_HOME", dir, true);

  Environment.set_variable("DEJA_DUP_LANGUAGE", "en", true);
  Test.bug_base("https://launchpad.net/bugs/%s");

  setup_gsettings();

  var unit = new TestSuite("unit");
  unit.add(make_backup_case("testing_mode", testing_mode));
  unit.add(make_backup_case("get_day", get_day));
  unit.add(make_backup_case("parse_dir", parse_dir));
  unit.add(make_backup_case("parse_dir_list", parse_dir_list));
  unit.add(make_backup_case("mode_to_string", mode_to_string));
  TestSuite.get_root().add_suite(unit);

  var restore = new TestSuite("restore");
  restore.add(make_backup_case("write_error", write_error));
  TestSuite.get_root().add_suite(restore);

  var rv = Test.run();

  if (Posix.system("rm -rf %s".printf(dir)) != 0)
    warning("Could not clean TEST_HOME %s", dir);

  return rv;
}
