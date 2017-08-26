/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
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

[CCode (cheader_filename = "unistd.h")]
extern long gethostid();

namespace DejaDup {

public const string INCLUDE_LIST_KEY = "include-list";
public const string EXCLUDE_LIST_KEY = "exclude-list";
public const string BACKEND_KEY = "backend";
public const string ROOT_PROMPT_KEY = "root-prompt";
public const string LAST_RUN_KEY = "last-run";
public const string LAST_BACKUP_KEY = "last-backup";
public const string LAST_RESTORE_KEY = "last-restore";
public const string PROMPT_CHECK_KEY = "prompt-check";
public const string NAG_CHECK_KEY = "nag-check";
public const string PERIODIC_KEY = "periodic";
public const string PERIODIC_PERIOD_KEY = "periodic-period";
public const string DELETE_AFTER_KEY = "delete-after";
public const string FULL_BACKUP_PERIOD_KEY = "full-backup-period";
public const string ALLOW_METERED_KEY = "allow-metered";

public errordomain BackupError {
  BAD_CONFIG,
  ALREADY_RUNNING
}

public enum TimestampType {
  NONE,
  BACKUP,
  RESTORE
}

public bool in_testing_mode()
{
  var testing_str = Environment.get_variable("DEJA_DUP_TESTING");
  return (testing_str != null && int.parse(testing_str) > 0);
}

public void update_last_run_timestamp(TimestampType type)
{
  TimeVal cur_time = TimeVal();
  cur_time.get_current_time();
  var cur_time_str = cur_time.to_iso8601();
  
  var settings = get_settings();
  settings.delay();
  settings.set_string(LAST_RUN_KEY, cur_time_str);
  if (type == TimestampType.BACKUP)
    settings.set_string(LAST_BACKUP_KEY, cur_time_str);
  else if (type == TimestampType.RESTORE)
    settings.set_string(LAST_RESTORE_KEY, cur_time_str);
  settings.apply();
}

// We manually reference this method, because Vala does not give us (as of
// 0.36 anyway...) a non-deprecated version that can still specify a base.
// So we use this one to avoid deprecation warnings during build.
[CCode (cname = "g_ascii_strtoull")]
public extern uint64 strtoull(string nptr, out char* endptr, uint _base);

public bool parse_version(string version_string, out int major, out int minor,
                          out int micro)
{
  major = 0;
  minor = 0;
  micro = 0;

  var ver_tokens = version_string.split(".");
  if (ver_tokens == null || ver_tokens[0] == null)
    return false;

  major = int.parse(ver_tokens[0]);
  // Don't error out if no minor or micro.
  if (ver_tokens[1] != null) {
    minor = int.parse(ver_tokens[1]);
    if (ver_tokens[2] != null)
      micro = int.parse(ver_tokens[2]);
  }

  return true;
}

public bool meets_version(int major, int minor, int micro,
                          int req_major, int req_minor, int req_micro)
{
  return (major > req_major) ||
         (major == req_major && minor > req_minor) ||
         (major == req_major && minor == req_minor && micro >= req_micro);
}

public string nice_prefix(string command)
{
  var cmd = command;
  int major, minor, micro;
  var utsname = Posix.utsname();
  parse_version(utsname.release, out major, out minor, out micro);

  // Check for ionice to be a good disk citizen
  if (Environment.find_program_in_path("ionice") != null) {
    // In Linux 2.6.25 and up, even normal users can request idle class
    if (utsname.sysname == "Linux" && meets_version(major, minor, micro, 2, 6, 25))
      cmd = "ionice -c3 " + cmd; // idle class
    else
      cmd = "ionice -c2 -n7 " + cmd; // lowest priority in best-effort class
  }

  // chrt's idle class is more-idle than nice, so prefer it
  if (utsname.sysname == "Linux" &&
      meets_version(major, minor, micro, 2, 6, 23) &&
      Environment.find_program_in_path("chrt") != null)
    cmd = "chrt --idle 0 " + cmd;
  else if (Environment.find_program_in_path("nice") != null)
    cmd = "nice -n19 " + cmd;

  return cmd;
}

public void run_deja_dup(string args, AppLaunchContext? ctx = null,
                         List<File>? files = null)
{
  var cmd = nice_prefix("deja-dup %s".printf(args));
  var flags = AppInfoCreateFlags.SUPPORTS_STARTUP_NOTIFICATION |
              AppInfoCreateFlags.SUPPORTS_URIS;
  try {
    var app = AppInfo.create_from_commandline(cmd, _("Déjà Dup Backup Tool"), flags);
    app.launch(files, ctx);
  }
  catch (Error e) {
    warning("%s\n", e.message);
  }
}

uint32 machine_id = 0;
uint32 get_machine_id()
{
  if (machine_id > 0)
    return machine_id;

  // First try /etc/machine-id, then /var/lib/dbus/machine-id, then hostid

  string machine_string;
  try {
    FileUtils.get_contents("/etc/machine-id", out machine_string);
  }
  catch (Error e) {}

  if (machine_string == null) {
    try {
      FileUtils.get_contents("/var/lib/dbus/machine-id", out machine_string);
    }
    catch (Error e) {}
  }

  if (machine_string != null)
    machine_id = (uint32)strtoull(machine_string, null, 16);

  if (machine_id == 0)
    machine_id = (uint32)gethostid();

  return machine_id;
}

DateTime most_recent_scheduled_date(TimeSpan period)
{
  // Compare days between epoch and current days.  Mod by period to find
  // scheduled dates.

  var epoch = new DateTime.from_unix_local(0);

  // Use early-morning local time for the epoch, not true midnight UNIX epoch:
  // (A) In cases like cloud services or shared servers, it will help to avoid
  //     all users hitting the server at the same time.  Hence the local time
  //     and randomization.  (LP: #1154920)
  // (B) Randomizing around 2-4 AM is probably a decent guess as for when to
  //     back up, if the user leaves the machine on and in the absence of more
  //     advanced scheduling support (LP: #479191)
  // (C) We randomize using machine id as a seed to make our predictions
  //     consistent between calls to this function and runs of deja-dup.
  var rand = new Rand.with_seed(get_machine_id());
  var early_hour = (TimeSpan)(rand.double_range(2, 4) * TimeSpan.HOUR);
  epoch = epoch.add(early_hour - epoch.get_utc_offset());

  var cur_date = new DateTime.now_local();

  var between = cur_date.difference(epoch);
  var mod = between % period;

  return cur_date.add(-1 * mod);
}

public string last_run_date(TimestampType type)
{
  var settings = DejaDup.get_settings();
  string last_run_string = null;
  if (type == TimestampType.BACKUP)
    last_run_string = settings.get_string(DejaDup.LAST_BACKUP_KEY);
  else if (type == TimestampType.RESTORE)
    last_run_string = settings.get_string(DejaDup.LAST_RESTORE_KEY);
  if (last_run_string == null || last_run_string == "")
    last_run_string = settings.get_string(DejaDup.LAST_RUN_KEY);
  return last_run_string;
}

/* Seems silly, but helpful for testing */
public TimeSpan get_day()
{
  if (in_testing_mode())
    return TimeSpan.SECOND * (TimeSpan)10; // a day is 10s when testing
  else
    return TimeSpan.DAY;
}

public DateTime? next_run_date()
{
  var settings = DejaDup.get_settings();
  var periodic = settings.get_boolean(DejaDup.PERIODIC_KEY);
  var period_days = settings.get_int(DejaDup.PERIODIC_PERIOD_KEY);

  var last_run_string = last_run_date(TimestampType.BACKUP);

  if (!periodic)
    return null;
  if (last_run_string == "")
    return new DateTime.now_local();
  if (period_days <= 0)
    period_days = 1;

  TimeVal last_run_tval = TimeVal();
  if (!last_run_tval.from_iso8601(last_run_string))
    return new DateTime.now_local();

  var period = (TimeSpan)period_days * get_day();

  var last_run = new DateTime.from_timeval_local(last_run_tval);
  var last_scheduled = most_recent_scheduled_date(period);

  if (last_scheduled.compare(last_run) <= 0)
    last_scheduled = last_scheduled.add(period);

  return last_scheduled;
}

// In seconds
public int get_prompt_delay()
{
  TimeSpan span = 0;
  if (DejaDup.in_testing_mode())
    span = TimeSpan.MINUTE * 2;
  else
    span = TimeSpan.DAY * 30;
  return (int)(span / TimeSpan.SECOND);
}

public bool has_seen_settings()
{
  return last_run_date(TimestampType.NONE) != "";
}

// This makes the check of whether we should tell user about backing up.
// For example, if a user has installed their OS and doesn't know about backing
// up, we might notify them after a month.
public bool make_prompt_check()
{
  var settings = DejaDup.get_settings();
  var prompt = settings.get_string(PROMPT_CHECK_KEY);

  if (prompt == "disabled")
    return false;
  else if (prompt == "") {
    update_prompt_time();
    return false;
  }
  else if (has_seen_settings())
    return false;

  // OK, monitor has run before but user hasn't yet backed up or restored.
  // Let's see whether we should prompt now.
  TimeVal last_run_tval = TimeVal();
  if (!last_run_tval.from_iso8601(prompt))
    return false;

  var last_run = new DateTime.from_timeval_local(last_run_tval);
  last_run = last_run.add_seconds(get_prompt_delay());

  var now = new DateTime.now_local();
  if (last_run.compare(now) <= 0) {
    run_deja_dup("--prompt");
    return true;
  }
  else
    return false;
}

private void update_time_key(string key, bool cancel)
{
  var settings = DejaDup.get_settings();

  if (settings.get_string(key) == "disabled")
    return; // never re-enable

  string cur_time_str;
  if (cancel) {
    cur_time_str = "disabled";
  }
  else {
    TimeVal cur_time = TimeVal();
    cur_time.get_current_time();
    cur_time_str = cur_time.to_iso8601();
  }

  settings.set_string(key, cur_time_str);
}

public void update_prompt_time(bool cancel = false)
{
  update_time_key(PROMPT_CHECK_KEY, cancel);
}

public void update_nag_time(bool cancel = false)
{
  update_time_key(NAG_CHECK_KEY, cancel);
}

// In seconds
public int get_nag_delay()
{
  TimeSpan span = 0;
  if (DejaDup.in_testing_mode())
    span = TimeSpan.MINUTE * 2;
  else
    span = TimeSpan.DAY * 30 * 2;
  return (int)(span / TimeSpan.SECOND);
}

// This makes the check of whether we should remind user about their password.
public bool is_nag_time()
{
  var settings = DejaDup.get_settings();
  var nag = settings.get_string(NAG_CHECK_KEY);
  var last_run_string = last_run_date(TimestampType.BACKUP);

  if (nag == "disabled" || last_run_string == "")
    return false;
  else if (nag == "") {
    update_nag_time();
    return false;
  }

  TimeVal last_check_tval = TimeVal();
  if (!last_check_tval.from_iso8601(nag))
    return false;

  var last_check = new DateTime.from_timeval_local(last_check_tval);
  last_check = last_check.add_seconds(get_nag_delay());

  var now = new DateTime.now_local();
  return (last_check.compare(now) <= 0);
}

public string get_folder_key(Settings settings, string key, bool abs_allowed = false)
{
  string folder = settings.get_string(key);
  if (folder.contains("$HOSTNAME")) {
    folder = folder.replace("$HOSTNAME", Environment.get_host_name());
    settings.set_string(key, folder);
  }
  if (!abs_allowed && folder.has_prefix("/"))
    folder = folder.substring(1);
  return folder;
}

public FilteredSettings get_settings(string? subdir = null)
{
  return new FilteredSettings(subdir);
}

ToolPlugin tool = null;
public ToolPlugin get_tool()
{
  assert(tool != null);
  return tool;
}

void initialize_tool_plugin() throws Error
{
  var engine = new Peas.Engine ();

  // For testing, we'll often point to in-tree tools
  string search_path = Environment.get_variable("DEJA_DUP_TOOLS_PATH");
  if (search_path == null || search_path == "")
    search_path = Path.build_filename(Config.PKG_LIBEXEC_DIR, "tools");
  engine.add_search_path(search_path, null);

  var info = engine.get_plugin_info("libduplicity.so");
  if (info == null)
    throw new SpawnError.FAILED(_("Could not find backup tool in %s.  Your installation is incomplete.").printf(search_path));
  if (!engine.try_load_plugin(info))
    throw new SpawnError.FAILED(_("Could not load backup tool.  Your installation is incomplete."));

  var extset = new Peas.ExtensionSet(engine, typeof(Peas.Activatable));
  var ext = extset.get_extension(info);
  tool = ext as ToolPlugin;
  if (tool == null)
    throw new SpawnError.FAILED(_("Backup tool is broken.  Your installation is incomplete."));

  tool.activate();
}

public bool initialize(out string header, out string msg)
{
  header = null;
  msg = null;

  // Get tool plugin to use
  try {
    initialize_tool_plugin();
  }
  catch (Error e) {
    header = _("Could not start backup tool");
    msg = e.message;
    return false;
  }

  migrate_settings();

  /* We do a little trick here.  BackendAuto -- which is the default
     backend on a fresh install of deja-dup -- will do some work to
     automatically suss out which backend should be used instead of it.
     So we request the current backend then drop it just to get that
     ball rolling in case this is the first time. */
  var unused_backend = DejaDup.Backend.get_default();
  unused_backend = null;

  // And cleanup from any previous runs
  clean_tempdirs.begin();

  return true;
}

void migrate_settings()
{
  // The old "File" schema has been split in three: local, remote, and drive

  var file = get_settings("File");
  if (file.get_boolean("migrated"))
    return;

  var drive = get_settings(DRIVE_ROOT);
  if (file.get_user_value("icon") != null)
    drive.set_string(DRIVE_ICON_KEY, file.get_string("icon"));
  if (file.get_user_value("short-name") != null)
    drive.set_string(DRIVE_NAME_KEY, file.get_string("short-name"));
  if (file.get_user_value("uuid") != null)
    drive.set_string(DRIVE_UUID_KEY, file.get_string("uuid"));
  if (file.get_user_value("relpath") != null)
    drive.set_string(DRIVE_FOLDER_KEY, file.get_value("relpath").get_bytestring());

  var type = file.get_string("type");
  var path = file.get_string("path");
  var gfile = File.parse_name(path);
  if (type == "normal" && path != "") {
    if (gfile.is_native()) {
      var local = get_settings(LOCAL_ROOT);
      local.set_string(LOCAL_FOLDER_KEY, gfile.get_path());
    } else {
      var remote = get_settings(REMOTE_ROOT);
      remote.set_string(REMOTE_URI_KEY, gfile.get_uri());
      remote.set_string(REMOTE_FOLDER_KEY, "");
    }
  }

  var settings = get_settings();
  if (settings.get_string(BACKEND_KEY) == "file") {
    if (type == "volume")
      settings.set_string(BACKEND_KEY, "drive");
    else if (gfile.is_native())
      settings.set_string(BACKEND_KEY, "local");
    else
      settings.set_string(BACKEND_KEY, "remote");
  }

  file.set_boolean("migrated", true);
}

public void i18n_setup()
{
  var localedir = Environment.get_variable("DEJA_DUP_LOCALEDIR");
  if (localedir == null || localedir == "")
    localedir = Config.LOCALE_DIR;
  var language = Environment.get_variable("DEJA_DUP_LANGUAGE");
  if (language != null && language != "")
    Environment.set_variable("LANGUAGE", language, true);
  Intl.setlocale(LocaleCategory.ALL, "");
  Intl.textdomain(Config.GETTEXT_PACKAGE);
  Intl.bindtextdomain(Config.GETTEXT_PACKAGE, localedir);
  Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
}

public string get_file_desc(File file)
{
  // First try to get the DESCRIPTION.  Else get the DISPLAY_NAME
  try {
    var info = file.query_info(FileAttribute.STANDARD_DISPLAY_NAME + "," +
                               FileAttribute.STANDARD_DESCRIPTION,
                               FileQueryInfoFlags.NONE, null);
    if (info.has_attribute(FileAttribute.STANDARD_DESCRIPTION))
      return info.get_attribute_string(FileAttribute.STANDARD_DESCRIPTION);
    else if (info.has_attribute(FileAttribute.STANDARD_DISPLAY_NAME))
      return info.get_attribute_string(FileAttribute.STANDARD_DISPLAY_NAME);
  }
  catch (Error e) {}

  var desc = Path.get_basename(file.get_parse_name());
  if (!file.is_native()) {
    var uri = DejaDupDecodedUri.decode_uri(file.get_uri());
    if (uri != null && uri.host != null && uri.host != "")
      desc = _("%1$s on %2$s").printf(desc, uri.host);
  }
  return desc;
}

static File home;
static File trash;

void ensure_special_paths ()
{
  if (home == null) {
    // Fill these out for the first time
    home = File.new_for_path(Environment.get_home_dir());
    trash = File.new_for_path(DejaDup.get_trash_path());
  }
}

public string get_display_name (File f)
{
  ensure_special_paths();

  if (f.has_prefix(home)) {
    // Unfortunately, the results of File.get_relative_path() are in local
    // encoding, not utf8, and there is no easy function to get a utf8 version.
    // So we manually convert.
    string s = home.get_relative_path(f);
    try {
      return "~/" + Filename.to_utf8(s, s.length, null, null);
    }
    catch (ConvertError e) {
      warning("%s\n", e.message);
    }
  }

  return f.get_parse_name();
}

public async string get_nickname (File f)
{
  ensure_special_paths();

  string s;
  if (f.equal(home)) {
    // Try to use the username in the display because several users have
    // previously assumed that "Home" meant "/home", and thus thought they
    // were backing up more than they were.  This should help avoid such data
    // loss accidents.
    try {
      var info = yield f.query_info_async(FileAttribute.STANDARD_DISPLAY_NAME,
                                          FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
      // Translators: this is the home folder and %s is the user's username
      s = _("Home (%s)").printf(info.get_display_name());
    }
    catch (Error e) {
      warning("%s\n", e.message);
      // Translators: this is the home folder
      s = _("Home");
    }
  }
  else if (f.equal(trash)) {
    // Translators: this is the trash folder
    s = _("Trash");
  }
  else 
    s = DejaDup.get_display_name(f);

  return s;
}

public int get_full_backup_threshold()
{
  // So, there are a few factors affecting how often to make a fresh full
  // backup:
  //
  // 1) The longer we wait, the more we're filling up the backend with 
  //    iterations on the same crap.
  // 2) The longer we wait, there's a higher risk that some bit will flip
  //    and the whole incremental chain afterwards is toast.
  // 3) The longer we wait, the less annoying we are, since full backups 
  //    take a long time.
  //
  // We default to 3 months.

  var settings = get_settings();
  var threshold = settings.get_int(FULL_BACKUP_PERIOD_KEY);
  if (threshold < 1)
    threshold = 84; // 3 months
  return threshold;
}

public Date get_full_backup_threshold_date()
{
  TimeVal now = TimeVal();
  now.get_current_time();
  
  Date date = Date();
  date.set_time_val(now);
  
  var days = get_full_backup_threshold();
  date.subtract_days(days);
  
  return date;
}

public Secret.Schema get_passphrase_schema()
{
  // Use freedesktop's schema id for historical reasons
  return new Secret.Schema("org.freedesktop.Secret.Generic",
                           Secret.SchemaFlags.NONE,
                           "owner", Secret.SchemaAttributeType.STRING,
                           "type", Secret.SchemaAttributeType.STRING);
}

public bool ensure_directory_exists(string path)
{
  var gfile = File.new_for_path(path);
  try {
    if (gfile.make_directory_with_parents())
      return true;
  }
  catch (IOError.EXISTS e) {
    return true; // ignore
  }
  catch (Error e) {
    warning("%s\n", e.message);
  }
  return false;
}

// By default, duplicity uses normal tmp folders like /tmp to store its
// in-process files.  These can get quite large, especially when restoring.
// You may need up to twice the size of the largest source file.
// Because /tmp may not be super large, especially on systems that use
// tmpfs by default (e.g. Fedora 18), we try to use a tempdir that is on
// the same partition as the source files.
public async string get_tempdir()
{
  var tempdirs = get_tempdirs();

  // First, decide the "main include".  Assume that if $HOME
  // is present, that is it.  Else, the first include we find decides it.
  // This is admittedly fast and loose, but our primary concern is just
  // avoiding silly choices like tmpfs or tiny special /tmp partitions.
  var settings = get_settings();
  var include_list = settings.get_file_list(INCLUDE_LIST_KEY);
  File main_include = null;
  var home = File.new_for_path(Environment.get_home_dir());
  foreach (var include in include_list) {
    if (include.equal(home)) {
      main_include = include;
      break;
    }
    else if (main_include == null)
      main_include = include;
  }
  if (main_include == null)
    return tempdirs[0];

  // Grab that include's fs ID
  string filesystem_id;
  try {
    var info = yield main_include.query_info_async(FileAttribute.ID_FILESYSTEM,
                                                   FileQueryInfoFlags.NONE);
    filesystem_id = info.get_attribute_string(FileAttribute.ID_FILESYSTEM);
  }
  catch (Error e) {
    return tempdirs[0];
  }

  // Then, see which of our possible tempdirs matches that partition.
  foreach (var tempdir in tempdirs) {
    string temp_id;
    ensure_directory_exists(tempdir);
    try {
      var gfile = File.new_for_path(tempdir);
      var info = yield gfile.query_info_async(FileAttribute.ID_FILESYSTEM,
                                              FileQueryInfoFlags.NONE);
      temp_id = info.get_attribute_string(FileAttribute.ID_FILESYSTEM);
    }
    catch (Error e) {
      continue;
    }
    if (temp_id == filesystem_id)
      return tempdir;
  }

  // Fallback to simply using the highest preferred tempdir
  return tempdirs[0];
}

public string[] get_tempdirs()
{
  var tempdir = Environment.get_variable("DEJA_DUP_TEMPDIR");
  if (tempdir != null && tempdir != "")
    return {tempdir};
  // Prefer directories that have their own cleanup logic in case ours isn't
  // run for a while.  (e.g. /tmp every boot, /var/tmp every now and then)
  return {Environment.get_tmp_dir(), "/var/tmp",
          Path.build_filename(Environment.get_user_cache_dir(), Config.PACKAGE,
                              "tmp")};
}

public async void clean_tempdirs()
{
  var tempdirs = get_tempdirs();
  const int NUM_ENUMERATED = 16;
  foreach (var tempdir in tempdirs) {
    var gfile = File.new_for_path(tempdir);

    // Now try to find and delete all files that start with "duplicity-"
    try {
      var enumerator = yield gfile.enumerate_children_async(
                         FileAttribute.STANDARD_NAME,
                         FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                         Priority.DEFAULT, null);
      while (true) {
        var infos = yield enumerator.next_files_async(NUM_ENUMERATED,
                                                      Priority.DEFAULT, null);
        foreach (FileInfo info in infos) {
          if (info.get_name().has_prefix("duplicity-")) {
            var child = gfile.get_child(info.get_name());
            yield new DejaDup.RecursiveDelete(child).start_async();
          }
        }
        if (infos.length() != NUM_ENUMERATED)
          break;
      }
    }
    catch (Error e) {
      // No worries
    }
  }
}

} // end namespace

