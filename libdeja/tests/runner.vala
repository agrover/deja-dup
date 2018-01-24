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

bool system_mode = false;

string get_top_builddir()
{
  var builddir = Environment.get_variable("top_builddir");
  if (builddir == null)
    builddir = "../../builddir";
  return builddir;
}

string get_top_srcdir()
{
  var srcdir = Environment.get_variable("top_srcdir");
  if (srcdir == null)
    srcdir = "../..";
  return srcdir;
}

string get_srcdir()
{
  var srcdir = Environment.get_variable("srcdir");
  if (srcdir == null)
    srcdir = ".";
  return srcdir;
}

void setup_gsettings()
{
  if (!system_mode) {
    var dir = Environment.get_variable("DEJA_DUP_TEST_HOME");

    var schema_dir = Path.build_filename(dir, "share", "glib-2.0", "schemas");
    DirUtils.create_with_parents(schema_dir, 0700);

    var data_dirs = Environment.get_variable("XDG_DATA_DIRS");
    Environment.set_variable("XDG_DATA_DIRS", "%s:%s".printf(Path.build_filename(dir, "share"), data_dirs), true);

    if (Posix.system("cp %s/data/org.gnome.DejaDup.gschema.xml %s".printf(get_top_srcdir(), schema_dir)) != 0)
      warning("Could not copy schema to %s", schema_dir);

    if (Posix.system("glib-compile-schemas %s".printf(schema_dir)) != 0)
      warning("Could not compile schemas in %s", schema_dir);
  }

  Environment.set_variable("GSETTINGS_BACKEND", "memory", true);
}

void backup_setup()
{
  // Intentionally don't create @TEST_HOME@/backup, as the mkdir test relies
  // on us not doing so.

  var dir = Environment.get_variable("DEJA_DUP_TEST_HOME");

  if (!system_mode)
    Environment.set_variable("DEJA_DUP_TOOLS_PATH", "%s/libdeja/tools/duplicity".printf(get_top_builddir()), true);

  Environment.set_variable("DEJA_DUP_TEST_MOCKSCRIPT", Path.build_filename(dir, "mockscript"), true);
  Environment.set_variable("XDG_CACHE_HOME", Path.build_filename(dir, "cache"), true);
  Environment.set_variable("PATH",
                           get_srcdir() + "/mock:" +
                             Environment.get_variable("DEJA_DUP_TEST_PATH"),
                           true);

  var tempdir = Path.build_filename(dir, "tmp");
  DejaDup.ensure_directory_exists(tempdir);
  Environment.set_variable("DEJA_DUP_TEMPDIR", tempdir, true);

  var settings = DejaDup.get_settings();
  settings.set_string(DejaDup.BACKEND_KEY, "local");
  settings = DejaDup.get_settings(DejaDup.LOCAL_ROOT);
  settings.set_string(DejaDup.LOCAL_FOLDER_KEY, Path.build_filename(dir, "backup"));
}

void backup_teardown()
{
  Environment.set_variable("PATH",
                           Environment.get_variable("DEJA_DUP_TEST_PATH"),
                           true);

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

  if (Posix.system("rm -r --interactive=never %s".printf(Environment.get_variable("DEJA_DUP_TEST_HOME"))) != 0)
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
  REMOVE,
  RESTORE,
  RESTORE_STATUS,
  LIST,
}

string make_fd_arg(bool as_root)
{
  return as_root ? "--log-file=?" : "--log-fd=?";
}

string default_args(BackupRunner br, Mode mode = Mode.NONE, bool encrypted = false, string extra = "", string include_args = "", string exclude_args = "", bool tmp_archive = false, int remove_n = -1, string? file_to_restore = null, bool as_root = false)
{
  var cachedir = Environment.get_variable("XDG_CACHE_HOME");
  var test_home = Environment.get_variable("DEJA_DUP_TEST_HOME");
  var backupdir = Path.build_filename(test_home, "backup");
  var restoredir = Path.build_filename(test_home, "restore");

  string enc_str = "";
  if (!encrypted)
    enc_str = "--no-encryption ";

  var tempdir = Path.build_filename(test_home, "tmp");
  var archive = tmp_archive ? "%s/duplicity-?".printf(tempdir) : "%s/deja-dup".printf(cachedir);

  var end_str = "%s'--verbosity=9' '--gpg-options=--no-use-agent' '--archive-dir=%s' '--tempdir=%s' '%s'".printf(enc_str, archive, tempdir, make_fd_arg(as_root));

  if (mode == Mode.CLEANUP)
    return "cleanup '--force' 'gio+file://%s' %s".printf(backupdir, end_str);
  else if (mode == Mode.RESTORE) {
    string file_arg = "", dest_arg = "";
    if (file_to_restore != null) {
      file_arg = "'--file-to-restore=%s' ".printf(file_to_restore.substring(1)); // skip root /
      dest_arg = file_to_restore;
    }
    return "'restore' %s%s'--force' 'gio+file://%s' '%s%s' %s".printf(file_arg, extra, backupdir, restoredir, dest_arg, end_str);
  }
  else if (mode == Mode.VERIFY)
    return "'restore' '--file-to-restore=%s/deja-dup/metadata' '--force' 'gio+file://%s' '%s/deja-dup/metadata' %s".printf(cachedir.substring(1), backupdir, cachedir, end_str);
  else if (mode == Mode.LIST)
    return "'list-current-files' %s'gio+file://%s' %s".printf(extra, backupdir, end_str);
  else if (mode == Mode.REMOVE)
    return "'remove-all-but-n-full' '%d' '--force' 'gio+file://%s' %s".printf(remove_n, backupdir, end_str);

  string source_str = "";
  if (mode == Mode.DRY || mode == Mode.BACKUP)
    source_str = "--volsize=1 / ";

  string dry_str = "";
  if (mode == Mode.DRY)
    dry_str = "--dry-run ";

  string args = "";

  if (br.is_full && !br.is_first && (mode == Mode.BACKUP || mode == Mode.DRY))
    args += "full ";

  if (mode == Mode.STATUS || mode == Mode.RESTORE_STATUS)
    args += "collection-status ";

  if (mode == Mode.STATUS || mode == Mode.NONE || mode == Mode.DRY || mode == Mode.BACKUP) {
    args += "'--exclude=%s' ".printf(backupdir);
    args += "'--exclude=%s/snap/*/*/.cache' ".printf(Environment.get_home_dir());
    args += "'--include=%s/deja-dup/metadata' ".printf(cachedir);

    string[] excludes1 = {"~/Downloads", "~/.local/share/Trash", "~/.xsession-errors", "~/.thumbnails", "~/.steam/root", "~/.Private", "~/.gvfs", "~/.ccache", "~/.adobe/Flash_Player/AssetCache"};
    foreach (string ex in excludes1) {
      ex = ex.replace("~", Environment.get_home_dir());
      if (FileUtils.test (ex, FileTest.IS_SYMLINK | FileTest.EXISTS))
        args += "'--exclude=%s' ".printf(ex);
    }

    var sys_sym_excludes = "";
    foreach (string sym in excludes1) {
      sym = sym.replace("~", Environment.get_home_dir());
      if (FileUtils.test (sym, FileTest.IS_SYMLINK) &&
          FileUtils.test (sym, FileTest.EXISTS)) {
        try {
          sym = FileUtils.read_link (sym);
          sym = Filename.to_utf8 (sym, -1, null, null);
          if (sym.has_prefix (Environment.get_home_dir()))
            args += "'--exclude=%s' ".printf(sym);
          else // delay non-home paths until very end
            sys_sym_excludes += "'--exclude=%s' ".printf(sym);
        }
        catch (Error e) {
          assert_not_reached();
        }
      }
    }

    if (FileUtils.test (Environment.get_home_dir(), FileTest.EXISTS)) {
      args += "'--include=%s' ".printf(Environment.get_home_dir());
    }
    args += include_args;

    string[] excludes2 = {"/sys", "/run", "/proc", tempdir};
    foreach (string ex in excludes2) {
      if (FileUtils.test (ex, FileTest.EXISTS))
        args += "'--exclude=%s' ".printf(ex);
    }

    args += "'--exclude=%s/deja-dup' '--exclude=%s' ".printf(cachedir, cachedir);

    // Really, these following two lists can be interweaved, depending on
    // what the paths are and the order in gsettings.  But tests are careful
    // to avoid having us duplicate the sorting logic in DuplicityJob by
    // putting /tmp paths at the end of exclude lists.  This lets us get away
    // with the simple logic of just appending the two lists.
    args += exclude_args;
    args += sys_sym_excludes;

    args += "'--exclude=**' ";
  }

  args += "%s %s%s'gio+file://%s' %s".printf(extra, dry_str, source_str, backupdir, end_str);

  return args;
}

class BackupRunner : Object
{
  public delegate void OpCallback (DejaDup.Operation op);
  public DejaDup.Operation op = null;
  public string path = null;
  public string script = null;
  public string? init_error = null;
  public bool success = true;
  public bool cancelled = false;
  public string? detail = null;
  public string? error_str = null;
  public string? error_regex = null;
  public string? error_detail = null;
  public string? restore_date = null;
  public List<File> restore_files = null;
  public OpCallback? callback = null;
  public bool is_full = false; // we don't often give INFO 3 which triggers is_full()
  public bool is_first = false;
  public int passphrases = 0;

  public void run()
  {
    if (script != null)
      run_script(script);

    if (path != null)
      Environment.set_variable("PATH", path, true);

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
      if (error_str != null && error_str != str)
        warning("Error string didn't match; expected %s, got %s", error_str, str);
      if (error_regex != null && !GLib.Regex.match_simple (error_regex, str))
        warning("Error string didn't match regex; expected %s, got %s", error_regex, str);
      if (error_detail != det)
        warning("Error detail didn't match; expected %s, got %s", error_detail, det);
      error_str = null;
      error_regex = null;
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

    Idle.add(() => {op.start.begin(); return false;});
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
  var user = Environment.get_user_name();
  var mockdir = get_srcdir() + "/mock";
  var cachedir = Environment.get_variable("XDG_CACHE_HOME");
  var test_home = Environment.get_variable("DEJA_DUP_TEST_HOME");
  var path = Environment.get_variable("PATH");
  return in.replace("@HOME@", home).
            replace("@MOCK_DIR@", mockdir).
            replace("@PATH@", path).
            replace("@USER@", user).
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

  if (keyfile.has_key(group, "RestoreFiles")) {
    var array = keyfile.get_string_list(group, "RestoreFiles");
    br.restore_files = new List<File>();
    foreach (var file in array)
      br.restore_files.append(File.new_for_path(replace_keywords(file)));
  }
  if (keyfile.has_key(group, "RestoreDate"))
    br.restore_date = keyfile.get_string(group, "RestoreDate");

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
  if (keyfile.has_key(group, "DiskFree"))
    Environment.set_variable("DEJA_DUP_TEST_SPACE_FREE", keyfile.get_string(group, "DiskFree"), true);
  if (keyfile.has_key(group, "InitError"))
    br.init_error = keyfile.get_string(group, "InitError");
  if (keyfile.has_key(group, "Error"))
    br.error_str = keyfile.get_string(group, "Error");
  if (keyfile.has_key(group, "ErrorRegex"))
    br.error_regex = keyfile.get_string(group, "ErrorRegex");
  if (keyfile.has_key(group, "ErrorDetail"))
    br.error_detail = keyfile.get_string(group, "ErrorDetail");
  if (keyfile.has_key(group, "Passphrases"))
    br.passphrases = keyfile.get_integer(group, "Passphrases");
  if (keyfile.has_key(group, "Path"))
    br.path = replace_keywords(keyfile.get_string(group, "Path"));
  if (keyfile.has_key(group, "Script"))
    br.script = replace_keywords(keyfile.get_string(group, "Script"));
  if (keyfile.has_key(group, "Settings")) {
    var settings_list = keyfile.get_string_list(group, "Settings");
    var settings = DejaDup.get_settings();
    foreach (var setting in settings_list) {
      try {
        var tokens = replace_keywords(setting).split("=");
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
  var type = keyfile.get_string(group, "Type");
  if (type == "backup")
    br.op = new DejaDup.OperationBackup(DejaDup.Backend.get_default());
  else if (type == "restore")
    br.op = new DejaDup.OperationRestore(DejaDup.Backend.get_default(), restoredir, br.restore_date, br.restore_files);
  else
    assert_not_reached();
}

string get_string_field(KeyFile keyfile, string group, string key) throws Error
{
  var field = keyfile.get_string(group, key);
  if (field == "^")
    return replace_keywords(keyfile.get_comment(group, key));
  if (field == "^sh")
    return run_script(replace_keywords(keyfile.get_comment(group, key))).strip();
  else
    return replace_keywords(field);
}

void process_duplicity_run_block(KeyFile keyfile, string run, BackupRunner br) throws Error
{
  string outputscript = null;
  string extra_args = "";
  string include_args = "";
  string exclude_args = "";
  string file_to_restore = null;
  bool encrypted = false;
  bool cancel = false;
  bool stop = false;
  bool passphrase = false;
  bool tmp_archive = false;
  bool as_root = false;
  int return_code = 0;
  int remove_n = -1;
  string script = null;
  Mode mode = Mode.NONE;

  var parts = run.split(" ", 2);
  var type = parts[0];
  var group = "Duplicity " + run;

  if (keyfile.has_group(group)) {
    if (keyfile.has_key(group, "ArchiveDirIsTmp"))
      tmp_archive = keyfile.get_boolean(group, "ArchiveDirIsTmp");
    if (keyfile.has_key(group, "AsRoot"))
      as_root = keyfile.get_boolean(group, "AsRoot");
    if (keyfile.has_key(group, "Cancel"))
      cancel = keyfile.get_boolean(group, "Cancel");
    if (keyfile.has_key(group, "Encrypted"))
      encrypted = keyfile.get_boolean(group, "Encrypted");
    if (keyfile.has_key(group, "ExtraArgs")) {
      extra_args = get_string_field(keyfile, group, "ExtraArgs");
      if (!extra_args.has_suffix(" "))
        extra_args += " ";
    }
    if (keyfile.has_key(group, "IncludeArgs")) {
      include_args = get_string_field(keyfile, group, "IncludeArgs");
      if (!include_args.has_suffix(" "))
        include_args += " ";
    }
    if (keyfile.has_key(group, "ExcludeArgs")) {
      exclude_args = get_string_field(keyfile, group, "ExcludeArgs");
      if (!exclude_args.has_suffix(" "))
        exclude_args += " ";
    }
    if (keyfile.has_key(group, "FileToRestore"))
      file_to_restore = get_string_field(keyfile, group, "FileToRestore");
    if (keyfile.has_key(group, "Output") && keyfile.get_boolean(group, "Output"))
      outputscript = replace_keywords(keyfile.get_comment(group, "Output"));
    else if (keyfile.has_key(group, "OutputScript") && keyfile.get_boolean(group, "OutputScript"))
      outputscript = run_script(replace_keywords(keyfile.get_comment(group, "OutputScript")));
    if (keyfile.has_key(group, "Passphrase"))
      passphrase = keyfile.get_boolean(group, "Passphrase");
    if (keyfile.has_key(group, "RemoveButN"))
      remove_n = keyfile.get_integer(group, "RemoveButN");
    if (keyfile.has_key(group, "Return"))
      return_code = keyfile.get_integer(group, "Return");
    if (keyfile.has_key(group, "Stop"))
      stop = keyfile.get_boolean(group, "Stop");
    if (keyfile.has_key(group, "Script"))
      script = get_string_field(keyfile, group, "Script");
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
  else if (type == "remove")
    mode = Mode.REMOVE;
  else if (type == "restore")
    mode = Mode.RESTORE;
  else if (type == "cleanup")
    mode = Mode.CLEANUP;
  else
    assert_not_reached();

  var cachedir = Environment.get_variable("XDG_CACHE_HOME");

  var dupscript = "ARGS: " + default_args(br, mode, encrypted, extra_args, include_args, exclude_args, tmp_archive, remove_n, file_to_restore, as_root);

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

  if (return_code != 0)
    dupscript += "\n" + "RETURN: %d".printf(return_code);

  if (as_root)
    dupscript += "\n" + "AS_ROOT";

  var verify_script = "mkdir -p %s/deja-dup/metadata && echo 'This folder can be safely deleted.\\n0' > %s/deja-dup/metadata/README".printf(cachedir, cachedir);
  if (mode == Mode.VERIFY)
    dupscript += "\n" + "SCRIPT: " + verify_script;
  if (script != null) {
    if (mode == Mode.VERIFY)
      dupscript += " && " + script;
    else
      dupscript += "\n" + "SCRIPT: " + script;
  }

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

const OptionEntry[] options = {
  {"system", 0, 0, OptionArg.NONE, ref system_mode, "Run against system install", null},
  {null}
};

int main(string[] args)
{
  Test.init(ref args);

  OptionContext context = new OptionContext("");
  context.add_main_entries(options, null);
  try {
    context.parse(ref args);
  } catch (Error e) {
    printerr("%s\n\n%s", e.message, context.get_help(true, null));
    return 1;
  }

  try {
    var dir = DirUtils.make_tmp("deja-dup-test-XXXXXX");
    Environment.set_variable("DEJA_DUP_TEST_HOME", dir, true);
  } catch (Error e) {
    printerr("Could not make temporary dir\n");
    return 1;
  }

  Environment.set_variable("DEJA_DUP_TESTING", "1", true);
  Environment.set_variable("DEJA_DUP_DEBUG", "1", true);
  Environment.set_variable("DEJA_DUP_LANGUAGE", "en", true);
  Test.bug_base("https://launchpad.net/bugs/%s");

  setup_gsettings();

  var script = "unknown/unknown";
  if (args.length > 1)
    script = args[1];
  Environment.set_variable("DEJA_DUP_TEST_SCRIPT", script, true);

  // Save PATH, as tests might reset it on us
  Environment.set_variable("DEJA_DUP_TEST_PATH",
                           Environment.get_variable("PATH"), true);

  var parts = script.split("/");
  var suitename = parts[parts.length - 2];
  var testname = parts[parts.length - 1].split(".")[0];

  var suite = new TestSuite(suitename);
  suite.add(new TestCase(testname, backup_setup, backup_run, backup_teardown));
  TestSuite.get_root().add_suite(suite);

  return Test.run();
}
