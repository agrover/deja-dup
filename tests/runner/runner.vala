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

void backup_setup()
{
  var dir = Environment.get_variable("DEJA_DUP_TEST_HOME");

  var cachedir = Path.build_filename(dir, "cache");
  DirUtils.create_with_parents(Path.build_filename(cachedir, "deja-dup"), 0700);

  DirUtils.create_with_parents(Path.build_filename(dir, "backup"), 0700);
  DirUtils.create_with_parents(Path.build_filename(dir, "restore"), 0700);

  Environment.set_variable("DEJA_DUP_TOOLS_PATH", "../../tools/duplicity", true);
  Environment.set_variable("DEJA_DUP_TEST_MOCKSCRIPT", Path.build_filename(dir, "mockscript"), true);
  Environment.set_variable("XDG_CACHE_HOME", cachedir, true);
  Environment.set_variable("PATH", "./mock:" + Environment.get_variable("PATH"), true);

  var settings = DejaDup.get_settings();
  settings.set_string(DejaDup.BACKEND_KEY, "file");
  settings = DejaDup.get_settings(DejaDup.FILE_ROOT);
  settings.set_string(DejaDup.FILE_PATH_KEY, Path.build_filename(dir, "backup"));
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

  var test_home = Environment.get_variable("DEJA_DUP_TEST_HOME");
  file = File.new_for_path(Path.build_filename(test_home, "backup"));
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

public enum Mode {
  NONE,
  STATUS,
  DRY,
  BACKUP,
  VERIFY,
  CLEANUP,
  RESTORE,
  RESTORE_STATUS,
  LIST,
}

string default_args(BackupRunner br, Mode mode = Mode.NONE, bool encrypted = false, string extra = "", bool tmp_archive = false)
{
  var cachedir = Environment.get_variable("XDG_CACHE_HOME");
  var test_home = Environment.get_variable("DEJA_DUP_TEST_HOME");
  var backupdir = Path.build_filename(test_home, "backup");
  var restoredir = Path.build_filename(test_home, "restore");

  var archive = tmp_archive ? "?" : "%s/deja-dup".printf(cachedir);

  if (mode == Mode.CLEANUP)
    return "cleanup '--force' 'file://%s' '--gio' %s'--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=%s' '--log-fd=?'".printf(backupdir, encrypted ? "" : "'--no-encryption' ", archive);
  else if (mode == Mode.RESTORE)
    return "'restore' '--gio' '--force' 'file://%s' '%s' %s'--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=%s' '--log-fd=?'".printf(backupdir, restoredir, encrypted ? "" : "'--no-encryption' ", archive);
  else if (mode == Mode.VERIFY)
    return "'restore' '--file-to-restore=%s/deja-dup/metadata' '--gio' '--force' 'file://%s' '%s/deja-dup/metadata' %s'--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=%s' '--log-fd=?'".printf(cachedir.substring(1), backupdir, cachedir, encrypted ? "" : "'--no-encryption' ", archive);
  else if (mode == Mode.LIST)
    return "'list-current-files' '--gio' 'file://%s' %s'--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=%s' '--log-fd=?'".printf(backupdir, encrypted ? "" : "'--no-encryption' ", archive);

  string source_str = "";
  if (mode == Mode.DRY || mode == Mode.BACKUP)
    source_str = "--volsize=1 / ";

  string dry_str = "";
  if (mode == Mode.DRY)
    dry_str = "--dry-run ";

  string enc_str = "";
  if (!encrypted)
    enc_str = "--no-encryption ";

  string args = "";

  if (br.is_full && !br.is_first && (mode == Mode.BACKUP || mode == Mode.DRY))
    args += "full ";

  if (mode == Mode.STATUS || mode == Mode.RESTORE_STATUS)
    args += "collection-status ";

  if (mode == Mode.STATUS || mode == Mode.NONE || mode == Mode.DRY || mode == Mode.BACKUP) {
    args += "'--exclude=%s' '--include=%s/deja-dup/metadata' ".printf(backupdir, cachedir);

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

  args += "%s%s'--gio' %s'file://%s' %s'--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=%s' '--log-fd=?'".printf(extra, dry_str, source_str, backupdir, enc_str, archive);

  return args;
}

class BackupRunner : Object
{
  public delegate void OpCallback (DejaDup.Operation op);
  public DejaDup.Operation op = null;
  public string? init_error = null;
  public bool success = true;
  public bool cancelled = false;
  public string? detail = null;
  public string? error_str = null;
  public string? error_detail = null;
  public OpCallback? callback = null;
  public bool is_full = false; // we don't often give INFO 3 which triggers is_full()
  public bool is_first = false;
  public int passphrases = 0;

  public void run()
  {
    string header, msg;
    if (!DejaDup.initialize(out header, out msg)) {
      if (header + "\n" + msg != init_error)
        warning("Init error didn't match; expected '%s', got '%s'", init_error, msg);
      return;
    }
    if (init_error != null)
      warning("Init error '%s' was expected", init_error);

    var loop = new MainLoop(null);
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
      if (passphrases == 0)
        warning("Passphrase needed but not provided");
      else {
        passphrases--;
        op.set_passphrase("test");
      }
    });

    op.question.connect((title, msg) => {
      Test.message("Question asked: %s, %s", title, msg);
    });

    var seen_is_full = false;
    op.is_full.connect((first) => {
      Test.message("Is full; is first: %d", (int)first);
      if (!is_full)
        warning("IsFull was not expected");
      if (is_first != first)
        warning("IsFirst didn't match; expected %d, got %d", (int) is_first, (int) first);
      seen_is_full = true;
    });

    op.start.begin();
    if (callback != null) {
      Timeout.add_seconds(5, () => {
        callback(op);
        return false;
      });
    }
    loop.run();

    if (!seen_is_full && is_full) {
      warning("IsFull was expected");
      if (is_first)
        warning("IsFirst was expected");
    }
    if (error_str != null)
      warning("Error str didn't match; expected %s, never got error", error_str);
    if (error_detail != null)
      warning("Error detail didn't match; expected %s, never got error", error_detail);

    if (passphrases > 0)
      warning("Passphrases expected, but not seen");
  }
}

void add_to_mockscript(string contents)
{
  var script = Environment.get_variable("DEJA_DUP_TEST_MOCKSCRIPT");
  string initial = "";
  try {
    FileUtils.get_contents(script, out initial, null);
    initial += "\n\n=== deja-dup ===";
  }
  catch (Error e) {
    initial = "";
  }

  var real_contents = initial + "\n" + contents;
  try {
    FileUtils.set_contents(script, real_contents);
  }
  catch (Error e) {
    assert_not_reached();
  }
}

string replace_keywords(string in)
{
  var home = Environment.get_home_dir();
  var cachedir = Environment.get_variable("XDG_CACHE_HOME");
  var test_home = Environment.get_variable("DEJA_DUP_TEST_HOME");
  return in.replace("@HOME@", home).
         replace("@XDG_CACHE_HOME@", cachedir).
         replace("@TEST_HOME@", test_home);
}

string run_script(string in)
{
  string output;
  string errstr;
  try {
    Process.spawn_sync(null, {"/bin/sh", "-c", in}, null, 0, null, out output, out errstr, null);
    if (errstr != null && errstr != "")
      warning("Error running script: %s", errstr);
  }
  catch (SpawnError e) {
    warning(e.message);
    assert_not_reached();
  }
  return output;
}

void process_operation_block(KeyFile keyfile, string group, BackupRunner br) throws Error
{
  var test_home = Environment.get_variable("DEJA_DUP_TEST_HOME");
  var restoredir = Path.build_filename(test_home, "restore");

  var type = keyfile.get_string(group, "Type");
  if (type == "backup")
    br.op = new DejaDup.OperationBackup();
  else if (type == "restore")
    br.op = new DejaDup.OperationRestore(restoredir);
  else
    assert_not_reached();
  if (keyfile.has_key(group, "Success"))
    br.success = keyfile.get_boolean(group, "Success");
  if (keyfile.has_key(group, "Canceled"))
    br.cancelled = keyfile.get_boolean(group, "Canceled");
  if (keyfile.has_key(group, "IsFull"))
    br.is_full = keyfile.get_boolean(group, "IsFull");
  if (keyfile.has_key(group, "IsFirst"))
    br.is_first = keyfile.get_boolean(group, "IsFirst");
  if (keyfile.has_key(group, "Detail"))
    br.detail = replace_keywords(keyfile.get_string(group, "Detail"));
  if (keyfile.has_key(group, "InitError"))
    br.init_error = keyfile.get_string(group, "InitError");
  if (keyfile.has_key(group, "Error"))
    br.error_str = keyfile.get_string(group, "Error");
  if (keyfile.has_key(group, "ErrorDetail"))
    br.error_detail = keyfile.get_string(group, "ErrorDetail");
  if (keyfile.has_key(group, "Passphrases"))
    br.passphrases = keyfile.get_integer(group, "Passphrases");
  if (keyfile.has_key(group, "Settings")) {
    var settings_list = keyfile.get_string_list(group, "Settings");
    var settings = DejaDup.get_settings();
    foreach (var setting in settings_list) {
      try {
        var tokens = setting.split("=");
        var key = tokens[0];
        var val = Variant.parse(null, tokens[1]);
        settings.set_value(key, val);
      }
      catch (Error e) {
        warning("%s\n", e.message);
        assert_not_reached();
      }
    }
  }
}

void process_duplicity_run_block(KeyFile keyfile, string run, BackupRunner br) throws Error
{
  string outputscript = null;
  string extra_args = "";
  bool encrypted = false;
  bool cancel = false;
  bool stop = false;
  bool passphrase = false;
  bool tmp_archive = false;
  string script = null;
  Mode mode = Mode.NONE;

  var parts = run.split(" ", 2);
  var type = parts[0];
  var group = "Duplicity " + run;

  if (keyfile.has_group(group)) {
    if (keyfile.has_key(group, "ArchiveDirIsTmp"))
      tmp_archive = keyfile.get_boolean(group, "ArchiveDirIsTmp");
    if (keyfile.has_key(group, "Cancel"))
      cancel = keyfile.get_boolean(group, "Cancel");
    if (keyfile.has_key(group, "Encrypted"))
      encrypted = keyfile.get_boolean(group, "Encrypted");
    if (keyfile.has_key(group, "ExtraArgs")) {
      extra_args = keyfile.get_string(group, "ExtraArgs");
      if (!extra_args.has_suffix(" "))
        extra_args += " ";
    }
    if (keyfile.has_key(group, "Output") && keyfile.get_boolean(group, "Output"))
      outputscript = replace_keywords(keyfile.get_comment(group, "Output"));
    else if (keyfile.has_key(group, "OutputScript") && keyfile.get_boolean(group, "OutputScript"))
      outputscript = run_script(replace_keywords(keyfile.get_comment(group, "OutputScript")));
    if (keyfile.has_key(group, "Passphrase"))
      passphrase = keyfile.get_boolean(group, "Passphrase");
    if (keyfile.has_key(group, "Stop"))
      stop = keyfile.get_boolean(group, "Stop");
    if (keyfile.has_key(group, "Script"))
      script = replace_keywords(keyfile.get_string(group, "Script"));
  }

  if (type == "status")
    mode = Mode.STATUS;
  else if (type == "status-restore")
    mode = Mode.RESTORE_STATUS; // should really consolidate the statuses
  else if (type == "dry")
    mode = Mode.DRY;
  else if (type == "list")
    mode = Mode.LIST;
  else if (type == "backup")
    mode = Mode.BACKUP;
  else if (type == "verify")
    mode = Mode.VERIFY;
  else if (type == "restore")
    mode = Mode.RESTORE;
  else if (type == "cleanup")
    mode = Mode.CLEANUP;
  else
    assert_not_reached();

  var cachedir = Environment.get_variable("XDG_CACHE_HOME");

  var dupscript = "ARGS: " + default_args(br, mode, encrypted, extra_args, tmp_archive);

  if (tmp_archive)
    dupscript += "\n" + "TMP_ARCHIVE";

  if (cancel) {
    dupscript += "\n" + "DELAY: 10";
    br.callback = (op) => {
      op.cancel();
    };
  }

  if (stop) {
    dupscript += "\n" + "DELAY: 10";
    br.callback = (op) => {
      op.stop();
    };
  }

  if (script != null)
    dupscript += "\n" + "SCRIPT: " + script;
  else if (mode == Mode.VERIFY)
    dupscript += "\n" + "SCRIPT: mkdir -p %s/deja-dup/metadata; echo 'This folder can be safely deleted.\\n0' > %s/deja-dup/metadata/README".printf(cachedir, cachedir);

  if (passphrase)
    dupscript += "\n" + "PASSPHRASE: test";
  else if (!encrypted) // when not encrypted, we always expect empty string
    dupscript += "\n" + "PASSPHRASE:";

  if (outputscript != null && outputscript != "")
    dupscript += "\n\n" + outputscript + "\n";

  add_to_mockscript(dupscript);
}

void process_duplicity_block(KeyFile keyfile, string group, BackupRunner br) throws Error
{
  var version = "9.9.99";
  if (keyfile.has_key(group, "Version"))
    version = keyfile.get_string(group, "Version");
  add_to_mockscript("ARGS: --version\n\nduplicity " + version + "\n");

  if (keyfile.has_key(group, "Runs")) {
    var runs = keyfile.get_string_list(group, "Runs");
    foreach (var run in runs)
      process_duplicity_run_block(keyfile, run, br);
  }
}

void backup_run()
{
  try {
    var script = Environment.get_variable("DEJA_DUP_TEST_SCRIPT");
    var keyfile = new KeyFile();
    keyfile.load_from_file(script, KeyFileFlags.KEEP_COMMENTS);

    var br = new BackupRunner();

    var groups = keyfile.get_groups();
    foreach (var group in groups) {
      if (group == "Operation")
        process_operation_block(keyfile, group, br);
      else if (group == "Duplicity")
        process_duplicity_block(keyfile, group, br);
    }

    br.run();
  }
  catch (Error e) {
    warning("%s\n", e.message);
    assert_not_reached();
  }
}

int main(string[] args)
{
  Test.init(ref args);

  var dir = "/tmp/deja-dup-test-XXXXXX";
  dir = DirUtils.mkdtemp(dir);
  Environment.set_variable("DEJA_DUP_TEST_HOME", dir, true);

  Environment.set_variable("DEJA_DUP_TESTING", "1", true);
  Environment.set_variable("DEJA_DUP_LANGUAGE", "en", true);
  Test.bug_base("https://launchpad.net/bugs/%s");

  setup_gsettings();

  var script = "unknown/unknown";
  if (args.length > 1)
    script = args[1];
  Environment.set_variable("DEJA_DUP_TEST_SCRIPT", script, true);

  var parts = script.split("/");
  var suitename = parts[parts.length - 2];
  var testname = parts[parts.length - 1].split(".")[0];

  var suite = new TestSuite(suitename);
  suite.add(new TestCase(testname, backup_setup, backup_run, backup_teardown));
  TestSuite.get_root().add_suite(suite);

  return Test.run();
}
