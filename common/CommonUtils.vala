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

namespace DejaDup {

public const string INCLUDE_LIST_KEY = "include-list";
public const string EXCLUDE_LIST_KEY = "exclude-list";
public const string BACKEND_KEY = "backend";
public const string ROOT_PROMPT_KEY = "root-prompt";
public const string WELCOMED_KEY = "welcomed";
public const string LAST_RUN_KEY = "last-run";
public const string LAST_BACKUP_KEY = "last-backup";
public const string LAST_RESTORE_KEY = "last-restore";
public const string PROMPT_CHECK_KEY = "prompt-check";
public const string PERIODIC_KEY = "periodic";
public const string PERIODIC_PERIOD_KEY = "periodic-period";
public const string DELETE_AFTER_KEY = "delete-after";

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

public void run_deja_dup(string args, AppLaunchContext? ctx = null,
                         List<File>? files = null)
{
  var cmd = "deja-dup %s".printf(args);

  // Check for ionice to be a good disk citizen
  if (Environment.find_program_in_path("ionice") != null) {
    // lowest priority in best-effort class
    // (can't use idle class as normal user on <2.6.25)
    cmd = "ionice -c2 -n7 " + cmd;
  }

  if (Environment.find_program_in_path("nice") != null)
    cmd = "nice " + cmd;

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

DateTime most_recent_scheduled_date(TimeSpan period)
{
  // Compare days between epoch and current days.  Mod by period to find
  // scheduled dates.

  var epoch = new DateTime.from_unix_local(0);
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
  return span / TimeSpan.SECOND;
}

public bool has_seen_settings()
{
  var settings = DejaDup.get_settings();
  return last_run_date(TimestampType.NONE) != "" ||
         settings.get_boolean(WELCOMED_KEY);
}

// This makes the check of whether we should tell user about backing up.
// For example, if a user has installed their OS and doesn't know about backing
// up, we might notify them after a month.
public void make_prompt_check()
{
  var settings = DejaDup.get_settings();
  var prompt = settings.get_string(PROMPT_CHECK_KEY);

  if (prompt == "disabled")
    return;
  else if (prompt == "") {
    update_prompt_time();
    return;
  }
  else if (has_seen_settings())
    return;

  // OK, monitor has run before but user hasn't yet backed up or restored.
  // Let's see whether we should prompt now.
  TimeVal last_run_tval = TimeVal();
  if (!last_run_tval.from_iso8601(prompt))
    return;

  var last_run = new DateTime.from_timeval_local(last_run_tval);
  last_run = last_run.add_seconds(get_prompt_delay());

  var now = new DateTime.now_local();
  if (last_run.compare(now) <= 0)
    run_deja_dup("--prompt");
}

public void update_prompt_time(bool cancel = false)
{
  var settings = DejaDup.get_settings();

  if (settings.get_string(PROMPT_CHECK_KEY) == "disabled")
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

  settings.set_string(PROMPT_CHECK_KEY, cur_time_str);
}

public string get_trash_path()
{
  return Path.build_filename(Environment.get_user_data_dir(), "Trash");
}

public string get_folder_key(SimpleSettings settings, string key)
{
  string folder = settings.get_string(key);
  if (folder.contains("$HOSTNAME")) {
    folder = folder.replace("$HOSTNAME", Environment.get_host_name());
    settings.set_string(key, folder);
  }
  if (folder.has_prefix("/"))
    folder = folder.substring(1);
  return folder;
}

public File? parse_dir(string dir)
{
  string s = dir;
  if (s == "$HOME")
    s = Environment.get_home_dir();
  else if (s == "$DESKTOP")
    s = Environment.get_user_special_dir(UserDirectory.DESKTOP);
  else if (s == "$DOCUMENTS")
    s = Environment.get_user_special_dir(UserDirectory.DOCUMENTS);
  else if (s == "$DOWNLOAD")
    s = Environment.get_user_special_dir(UserDirectory.DOWNLOAD);
  else if (s == "$MUSIC")
    s = Environment.get_user_special_dir(UserDirectory.MUSIC);
  else if (s == "$PICTURES")
    s = Environment.get_user_special_dir(UserDirectory.PICTURES);
  else if (s == "$PUBLIC_SHARE")
    s = Environment.get_user_special_dir(UserDirectory.PUBLIC_SHARE);
  else if (s == "$TEMPLATES")
    s = Environment.get_user_special_dir(UserDirectory.TEMPLATES);
  else if (s == "$TRASH")
    s = get_trash_path();
  else if (s == "$VIDEOS")
    s = Environment.get_user_special_dir(UserDirectory.VIDEOS);
  else if (Uri.parse_scheme(s) == null && !Path.is_absolute(s))
    s = Path.build_filename(Environment.get_home_dir(), s);
  else
    return File.parse_name(s);

  if (s != null)
    return File.new_for_path(s);
  else
    return null;
}

public File[] parse_dir_list(string*[] dirs)
{
  File[] rv = new File[0];
  
  foreach (string s in dirs) {
    var f = parse_dir(s);
    if (f != null)
      rv += f;
  }
  
  return rv;
}

bool settings_read_only = false;
HashTable<string, SimpleSettings> settings_table = null;
public void set_settings_read_only(bool ro)
{
  settings_read_only = ro;
  if (settings_read_only) {
    // When read only, we also need to make sure everyone shares the same
    // settings object.  Otherwise, they will not notice the changes other
    // parts of the code make.
    settings_table = new HashTable<string, SimpleSettings>.full(str_hash,
                                                                str_equal,
                                                                g_free,
                                                                g_object_unref);
  }
  else {
    settings_table = null;
  }
}

public SimpleSettings get_settings(string? subdir = null)
{
  string schema = "org.gnome.DejaDup";
  if (subdir != null && subdir != "")
    schema += "." + subdir;
  SimpleSettings rv;
  if (settings_read_only) {
    rv = settings_table.lookup(schema);
    if (rv == null) {
      rv = new SimpleSettings(schema, true);
      rv.delay(); // never to be apply()'d again
      settings_table.insert(schema, rv);
    }
  }
  else {
    rv = new SimpleSettings(schema, false);
  }
  return rv;
}

const string SSH_USERNAME_KEY = "username";
const string SSH_SERVER_KEY = "server";
const string SSH_PORT_KEY = "port";
const string SSH_DIRECTORY_KEY = "directory";

// Once, we didn't use GIO, but had a special SSH backend for duplicity that
// would tell duplicity to use its own SSH handling.  We convert those gsettings
// values to the new ones here.
void convert_ssh_to_file()
{
  var settings = get_settings();
  var backend = settings.get_string(BACKEND_KEY);
  if (backend == "ssh") {
    settings.set_string(BACKEND_KEY, "file");
    var ssh_settings = get_settings("SSH");
    var server = ssh_settings.get_string(SSH_SERVER_KEY);
    if (server != null && server != "") {
      var username = ssh_settings.get_string(SSH_USERNAME_KEY);
      var port = ssh_settings.get_int(SSH_PORT_KEY);
      var directory = ssh_settings.get_string(SSH_DIRECTORY_KEY);
      
      var gio_uri = "ssh://";
      if (username != null && username != "")
        gio_uri += username + "@";
      gio_uri += server;
      if (port > 0 && port != 22)
        gio_uri += ":" + port.to_string();
      if (directory == null || directory == "")
        gio_uri += "/";
      else if (directory[0] != '/')
        gio_uri += "/" + directory;
      else
        gio_uri += directory;
      
      var file_settings = get_settings(FILE_ROOT);
      file_settings.set_string(FILE_PATH_KEY, gio_uri);
    }
  }
}

void convert_s3_folder_to_hostname()
{
  // So historically, the default S3 folder was '/'.  But in keeping with other
  // cloud backends, the desire to use a hostname in the default folder would
  // make one want to change that default.  But since the user might not have
  // actually changed the default, we don't want to upgrade the folder default
  // in such a case.  So we check here if the user has ever backed up before
  // and if not (or not using S3), then we update the field.
  var settings = get_settings();
  var s3_settings = get_settings(S3_ROOT);
  if ((s3_settings.get_string(S3_FOLDER_KEY) == "" ||
       s3_settings.get_string(S3_FOLDER_KEY) == "/") &&
      (Backend.get_default_type() != "s3" ||
       settings.get_string(LAST_RUN_KEY) == "")) {
    s3_settings.set_string(S3_FOLDER_KEY, "$HOSTNAME");
  }
}

public bool meet_requirements(out string header, out string msg)
{
  return DuplicityInfo.get_default().check_duplicity_version(out header, out msg);
}

public bool initialize(out string header, out string msg)
{
  if (!meet_requirements(out header, out msg))
    return false;

  convert_ssh_to_file();
  convert_s3_folder_to_hostname();

  /* We do a little trick here.  BackendAuto -- which is the default
     backend on a fresh install of deja-dup -- will do some work to
     automatically suss out which backend should be used instead of it.
     So we request the current backend then drop it just to get that
     ball rolling in case this is the first time. */
  var unused_backend = DejaDup.Backend.get_default();
  unused_backend = null;

  return true;
}

public void i18n_setup()
{
  var localedir = Environment.get_variable("DEJA_DUP_LOCALEDIR");
  if (localedir == null || localedir == "")
    localedir = Config.LOCALE_DIR;
  var language = Environment.get_variable("DEJA_DUP_LANGUAGE");
  if (language != null && language != "")
    Environment.set_variable("LANGUAGE", language, true);
  Intl.textdomain(Config.GETTEXT_PACKAGE);
  Intl.bindtextdomain(Config.GETTEXT_PACKAGE, localedir);
  Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
}

public string get_file_desc(File file)
{
  // First try to get the DESCRIPTION.  Else get the DISPLAY_NAME
  try {
    var info = file.query_info(FILE_ATTRIBUTE_STANDARD_DISPLAY_NAME + "," +
                               FILE_ATTRIBUTE_STANDARD_DESCRIPTION,
                               FileQueryInfoFlags.NONE, null);
    if (info.has_attribute(FILE_ATTRIBUTE_STANDARD_DESCRIPTION))
      return info.get_attribute_string(FILE_ATTRIBUTE_STANDARD_DESCRIPTION);
    else if (info.has_attribute(FILE_ATTRIBUTE_STANDARD_DISPLAY_NAME))
      return info.get_attribute_string(FILE_ATTRIBUTE_STANDARD_DISPLAY_NAME);
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
      return Filename.to_utf8(s, s.length, null, null);
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
      var info = yield f.query_info_async(FILE_ATTRIBUTE_STANDARD_DISPLAY_NAME,
                                          FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
      // Translators: %s is the user's username
      s = _("Home (%s)").printf(info.get_display_name());
    }
    catch (Error e) {
      warning("%s\n", e.message);
      s = _("Home");
    }
  }
  else if (f.equal(trash))
    s = _("Trash");
  else 
    s = DejaDup.get_display_name(f);

  return s;
}

public int get_full_backup_threshold()
{
  int threshold = 7 * 6; // default to 6 weeks
  // So, there are a few factors affecting how often to make a fresh full
  // backup:
  // 1) The longer we wait, the more we're filling up the backend with 
  //    iterations on the same crap.
  // 2) The longer we wait, there's a higher risk that some bit will flip
  //    and the whole backup is toast.
  // 3) The longer we wait, the less annoying we are, since full backups 
  //    take a long time.
  // So we try to do them at reasonable times.  But almost nobody should be
  // going longer than 6 months without a full backup.  Further, we want
  // to try to keep at least 2 full backups around, so also don't allow a
  // longer full threshold than half the delete age.
  // 
  // 'daily' gets 2 weeks: 1 * 12 => 2 * 7
  // 'weekly' gets 3 months: 7 * 12
  // 'biweekly' gets 6 months: 14 * 12
  // 'monthly' gets 6 months: 28 * 12 => 24 * 7
  var max = 24 * 7; // 6 months
  var min = 4 * 7; // 4 weeks
  var scale = 12;
  var min_fulls = 2;
  
  var settings = get_settings();
  var delete_age = settings.get_int(DELETE_AFTER_KEY);
  if (delete_age > 0)
    max = int.min(delete_age/min_fulls, max);
  
  var periodic = settings.get_boolean(PERIODIC_KEY);
  if (periodic) {
    var period = settings.get_int(PERIODIC_PERIOD_KEY);
    threshold = period * scale;
    threshold.clamp(min, max);
  }
  else
    threshold = max;
  
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

} // end namespace

