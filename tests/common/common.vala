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
  Environment.set_variable("PATH", "./mock:" + Environment.get_variable("PATH"), true);

  try {
    string scriptname;
    var scriptfd = FileUtils.open_tmp("deja-dup-test-XXXXXX", out scriptname);
    Posix.close(scriptfd);
    Environment.set_variable("DEJA_DUP_TEST_MOCKSCRIPT", scriptname, true);
  }
  catch (Error e) {
    assert_not_reached();
  }

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
    try {
      file.delete(null);
    }
    catch (Error e) {
      assert_not_reached();
    }
    // Fail the test, something went wrong
    warning("Mockscript file still exists");
  }

  file = File.new_for_path("/tmp/not/a/thing");
  try {
    file.delete(null);
  }
  catch (Error e) {
    assert_not_reached();
  }

  Environment.unset_variable("DEJA_DUP_TEST_MOCKSCRIPT");
}

void set_script(string contents)
{
  try {
    var script = Environment.get_variable("DEJA_DUP_TEST_MOCKSCRIPT");
    FileUtils.set_contents(script, contents);
  }
  catch (Error e) {
    assert_not_reached();
  }
}

delegate void OpCallback (DejaDup.Operation op);

void run_backup(bool success = true, bool cancelled = false, string? detail = null, OpCallback? cb = null)
{
  var loop = new MainLoop(null);
  var op = new DejaDup.OperationBackup();
  op.done.connect((op, s, c) => {
    if (success != s)
      warning("Success didn't match; expected %d, got %d", (int) success, (int) s);
    if (cancelled != c)
      warning("Cancel didn't match; expected %d, got %d", (int) cancelled, (int) c);
    loop.quit();
  });

  op.raise_error.connect((str, detail) => {
    Test.message("Error: %s, %s", str, detail);
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
  op.is_full.connect((isfull) => {
    Test.message("Is full? %d", (int)isfull);
  });

  op.start();
  if (cb != null) {
    Timeout.add_seconds(3, () => {
      cb(op);
      return false;
    });
  }
  loop.run();
}

enum Mode {
  NONE,
  DRY,
  BACKUP,
  CLEANUP,
}

string default_args(Mode mode = Mode.NONE, bool encrypted = false, string extra = "")
{
  if (mode == Mode.CLEANUP)
    return "'--force' 'file:///tmp/not/a/thing' '--gio' '--no-encryption' '--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=/home/ME/.cache/deja-dup' '--log-fd=?'";

  string source_str = "";
  if (mode == Mode.DRY || mode == Mode.BACKUP)
    source_str = " --volsize=50 /";

  string dry_str = "";
  if (mode == Mode.DRY)
    dry_str = " --dry-run";

  string enc_str = "";
  if (!encrypted)
    enc_str = " --no-encryption";

  return "'--exclude=/tmp/not/a/thing' '--exclude=/home/ME/Downloads' '--exclude=/home/ME/.local/share/Trash' '--exclude=/home/ME/.xsession-errors' '--exclude=/home/ME/.thumbnails' '--exclude=/home/ME/.Private' '--exclude=/home/ME/.gvfs' '--exclude=/home/ME/.adobe/Flash_Player/AssetCache' '--exclude=/home/ME/.cache/deja-dup' '--exclude=/home/ME/.cache' '--include=/home/ME' '--exclude=/home/.ecryptfs/ME/.Private' '--exclude=/sys' '--exclude=/proc' '--exclude=/tmp' '--exclude=**'%s%s '--gio'%s 'file:///tmp/not/a/thing'%s '--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=/home/ME/.cache/deja-dup' '--log-fd=?'".printf(extra, dry_str, source_str, enc_str);
}

void bad_hostname()
{
  set_script("""
ARGS: collection-status %s

INFO 3

=== deja-dup ===
ARGS: full %s
RETURN: 3

ERROR 3 new old

=== deja-dup ===
ARGS: full %s

=== deja-dup ===
ARGS: full %s

""".printf(default_args(),
           default_args(Mode.DRY),
           default_args(Mode.DRY, false, " --allow-source-mismatch"),
           default_args(Mode.BACKUP, false, " --allow-source-mismatch")));
  run_backup();
}

void cancel_noop()
{
  set_script("""
ARGS: collection-status %s
DELAY: 10

""".printf(default_args()));
  run_backup(false, true, null, (op) => {
    op.cancel();
  });
}

void cancel()
{
  set_script("""
ARGS: collection-status %s

=== deja-dup ===
ARGS: %s

=== deja-dup ===
ARGS: %s
DELAY: 10

=== deja-dup ===
ARGS: cleanup %s

""".printf(default_args(),
           default_args(Mode.DRY),
           default_args(Mode.BACKUP),
           default_args(Mode.CLEANUP)));
  run_backup(false, true, null, (op) => {
    op.cancel();
  });
}

void stop()
{
  set_script("""
ARGS: collection-status %s

=== deja-dup ===
ARGS: %s

=== deja-dup ===
ARGS: %s
DELAY: 10

""".printf(default_args(),
           default_args(Mode.DRY),
           default_args(Mode.BACKUP)));
  run_backup(true, true, null, (op) => {
    op.stop();
  });
}

int main(string[] args)
{
  Test.init(ref args);

  Environment.set_variable("DEJA_DUP_LANGUAGE", "en", true);
  Environment.set_variable("GSETTINGS_BACKEND", "memory", true);
  Test.bug_base("https://launchpad.net/bugs/%s");

  Test.add_func("/unit/utils/testing_mode", testing_mode);
  Test.add_func("/unit/utils/get_day", get_day);
  Test.add_func("/unit/utils/parse_dir", parse_dir);
  Test.add_func("/unit/utils/parse_dir_list", parse_dir_list);
  Test.add_func("/unit/operation/mode_to_string", mode_to_string);

  var backup = new TestSuite("backup");
  backup.add(new TestCase("bad_hostname", backup_setup, bad_hostname, backup_teardown));
  backup.add(new TestCase("cancel_noop", backup_setup, cancel_noop, backup_teardown));
  backup.add(new TestCase("cancel", backup_setup, cancel, backup_teardown));
  backup.add(new TestCase("stop", backup_setup, stop, backup_teardown));
  TestSuite.get_root().add_suite(backup);

  return Test.run();
}
