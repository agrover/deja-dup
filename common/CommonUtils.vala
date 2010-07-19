/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008,2009 Michael Terry <mike@mterry.name>

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
public const string ENCRYPT_KEY = "encrypt";
public const string LAST_RUN_KEY = "last-run";
public const string PERIODIC_KEY = "periodic";
public const string PERIODIC_PERIOD_KEY = "periodic-period";
public const string DELETE_AFTER_KEY = "delete-after";

public void update_last_run_timestamp() throws Error
{
  TimeVal cur_time = TimeVal();
  cur_time.get_current_time();
  var cur_time_str = cur_time.to_iso8601();
  
  var settings = get_settings();
  settings.set_string(LAST_RUN_KEY, cur_time_str);
}

public string get_trash_path()
{
  return Path.build_filename(Environment.get_user_data_dir(), "Trash");
}

public File parse_dir(string dir)
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
  else if (!Path.is_absolute(s))
    s = Path.build_filename(Environment.get_home_dir(), s);
  
  return File.new_for_path(s);
}

public File[] parse_dir_list(string*[] dirs)
{
  File[] rv = new File[dirs.length];
  
  int i = 0;
  foreach (string s in dirs)
    rv[i++] = parse_dir(s);
  
  return rv;
}

public bool test_bus_claimed(string busname)
{
  try {
    var conn = DBus.Bus.@get(DBus.BusType.SESSION);

    dynamic DBus.Object bus = conn.get_object ("org.freedesktop.DBus",
                                               "/org/freedesktop/DBus",
                                               "org.freedesktop.DBus");

    string result = bus.get_name_owner("org.gnome.deja-dup." + busname);
    return result != null && result != "";
  }
  catch (Error e) {
    return false;
  }
}

public bool set_bus_claimed(string busname, bool claim)
{
  try {
    var conn = DBus.Bus.@get(DBus.BusType.SESSION);
    
    dynamic DBus.Object bus = conn.get_object ("org.freedesktop.DBus",
                                               "/org/freedesktop/DBus",
                                               "org.freedesktop.DBus");
    
    if (claim) {
      // Try to register service in session bus.
      // The flag '4' means do not add ourselves to the queue of applications
      // wanting the name, if this request fails.
      uint32 result = bus.request_name("org.gnome.deja-dup." + busname,
                                       (uint32)4);
      
      if (result == DBus.RequestNameReply.EXISTS)
        return false;
    }
    else {
      // We have to assign reply to a variable because it is a dynamic binding
      // and otherwise, generated code will expect no return value.
      uint32 result = bus.release_name("org.gnome.deja-dup." + busname);
      if (result != 1)
        warning("Unexpected reply of %u when releasing busname %s\n", result, busname);
    }
  }
  catch (Error e) {
    warning("%s\n", e.message);
  }
  
  return true;
}

public Settings get_settings(string? subdir = null)
{
  string schema = "org.gnome.DejaDup";
  if (subdir != null && subdir != "")
    schema += "." + subdir;
  return new Settings(schema);
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
      if (port > 0)
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

public void initialize()
{
  convert_ssh_to_file();
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
  
  return Path.get_basename(file.get_parse_name());
}

public string get_location_desc()
{
  try {
    var desc = Backend.get_default().get_location_pretty();
    if (desc != null && desc != "")
      return desc;
  }
  catch (Error e) {}

  return _("Unknown");
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

