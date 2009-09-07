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

public const string INCLUDE_LIST_KEY = "/apps/deja-dup/include-list";
public const string EXCLUDE_LIST_KEY = "/apps/deja-dup/exclude-list";
public const string BACKEND_KEY = "/apps/deja-dup/backend";
public const string ENCRYPT_KEY = "/apps/deja-dup/encrypt";
public const string LAST_RUN_KEY = "/apps/deja-dup/last-run";
public const string PERIODIC_KEY = "/apps/deja-dup/periodic";
public const string PERIODIC_PERIOD_KEY = "/apps/deja-dup/periodic-period";
public const string DELETE_AFTER_KEY = "/apps/deja-dup/delete-after";

public void update_last_run_timestamp() throws Error
{
  TimeVal cur_time = TimeVal();
  cur_time.get_current_time();
  var cur_time_str = cur_time.to_iso8601();
  
  var client = get_gconf_client();
  client.set_string(DejaDup.LAST_RUN_KEY, cur_time_str);
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

public File[] parse_dir_list(SList<string>? dirs)
{
  if (dirs == null)
    return new File[0];
  
  File[] rv = new File[dirs.length()];
  
  int i = 0;
  foreach (string s in dirs)
    rv[i++] = parse_dir(s);
  
  return rv;
}

public void show_uri(Gtk.Window parent, string link)
{
  try {
    Gdk.Screen screen = parent.get_screen();
    Gtk.show_uri(screen, link, Gdk.CURRENT_TIME);
  } catch (Error e) {
    Gtk.MessageDialog dlg = new Gtk.MessageDialog(parent, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, _("Could not display %s"), link);
    dlg.format_secondary_text("%s", e.message);
    dlg.run();
    dlg.destroy();
  }
}


void handle_about_uri(Gtk.AboutDialog about, string link)
{
  show_uri(about, link);
}

void handle_about_mail(Gtk.AboutDialog about, string link)
{
  show_uri(about, "mailto:%s".printf(link));
}

// These need to be namespace-wide to prevent an odd compiler syntax error.
const string[] authors = {"Andrew Fister <temposs@gmail.com>",
                          "Michael Terry <mike@mterry.name>",
                          null};

const string[] artists = {"Andreas Nilsson <nisses.mail@home.se>",
                          "Jakub Steiner <jimmac@novell.com>",
                          "Michael Terry <mike@mterry.name>",
                          null};

const string[] documenters = {"Michael Terry <mike@mterry.name>",
                              null};

public void show_about(Object owner, Gtk.Window? parent)
{
  Gtk.AboutDialog about = (Gtk.AboutDialog)owner.get_data("about-dlg");
  
  if (about != null)
  {
    about.present ();
    return;
  }
  
  about = new Gtk.AboutDialog ();
  about.set_email_hook (handle_about_mail);
  about.set_url_hook (handle_about_uri);
  about.title = _("About Déjà Dup");
  about.authors = authors;
  about.artists = artists;
  about.documenters = documenters;
  about.translator_credits = _("translator-credits");
  about.logo_icon_name = Config.PACKAGE;
  about.version = Config.VERSION;
  about.website = "https://launchpad.net/deja-dup";
  about.license = "%s\n\n%s\n\n%s".printf (
    _("This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version."),
    _("This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details."),
    _("You should have received a copy of the GNU General Public License along with this program.  If not, see http://www.gnu.org/licenses/."));
  about.wrap_license = true;
  
  owner.set_data("about-dlg", about);
  about.set_data("owner", owner);
  
  about.set_transient_for(parent);
  about.response.connect((dlg, resp) => {
    Object about_owner = (Object)dlg.get_data("owner");
    about_owner.set_data("about-dlg", null);
    dlg.destroy();
  });
  
  about.show();
}

public Gtk.Window? get_topwindow(Gtk.Widget w)
{
  w = w.get_toplevel();
  if (w != null && w.is_toplevel())
    return (Gtk.Window)w;
  else
    return null;
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
      uint32 result = bus.request_name("net.launchpad.deja-dup." + busname,
                                       (uint32)4);
      
      if (result == DBus.RequestNameReply.EXISTS)
        return false;
    }
    else {
      // We have to assign reply to a variable because it is a dynamic binding
      // and otherwise, generated code will expect no return value.
      uint32 result = bus.release_name("net.launchpad.deja-dup." + busname);
      result = result; // to silence warning about not using it.
    }
  }
  catch (Error e) {
    warning("%s\n", e.message);
  }
  
  return true;
}

GConf.Client client;
void set_gconf_client()
{
  var source_str = Environment.get_variable("GCONF_CONFIG_SOURCE");
  if (source_str != null) {
    try {
      var engine = GConf.Engine.get_for_address(source_str);
      client = GConf.Client.get_for_engine(engine);
    }
    catch (Error e) {
      printerr("%s\n", e.message);
    }
  }
}

public GConf.Client get_gconf_client()
{
  if (client == null)
    client = GConf.Client.get_default();
  return client;
}

const string SSH_USERNAME_KEY = "/apps/deja-dup/ssh/username";
const string SSH_SERVER_KEY = "/apps/deja-dup/ssh/server";
const string SSH_PORT_KEY = "/apps/deja-dup/ssh/port";
const string SSH_DIRECTORY_KEY = "/apps/deja-dup/ssh/directory";

// Once, we didn't use GIO, but had a special SSH backend for duplicity that
// would tell duplicity to use its own SSH handling.  We convert those gconf
// values to the new ones here.
void convert_ssh_to_file()
{
  var client = get_gconf_client();
  try {
    var backend = client.get_string(BACKEND_KEY);
    if (backend == "ssh") {
      client.set_string(BACKEND_KEY, "file");
      var server = client.get_string(SSH_SERVER_KEY);
      if (server != null && server != "") {
        var username = client.get_string(SSH_USERNAME_KEY);
        var port = client.get_int(SSH_PORT_KEY);
        var directory = client.get_string(SSH_DIRECTORY_KEY);
        
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
        
        client.set_string(FILE_PATH_KEY, gio_uri);
      }
    }
  }
  catch (Error e) {
    warning("%s\n", e.message);
  }
}

public void initialize()
{
  set_gconf_client();
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
  catch (Error e) {warning("%s\n", e.message);}
  
  return Path.get_basename(file.get_parse_name());
}

public string get_location_desc()
{
  File file = null;
  try {
    var val = client.get_string(BACKEND_KEY);
    if (val == "s3")
      return _("Amazon S3");
    else {
      val = client.get_string(FILE_PATH_KEY);
      if (val == null)
        val = ""; // current directory
      file = File.parse_name(val);
    }
    
    return get_file_desc(file);
  }
  catch (Error e) {
    warning("%s\n", e.message);
    return _("Unknown");
  }
}

public int get_full_backup_threshold()
{
  int threshold = 7 * 6; // default to 6 weeks
  try {
    // So, there are a few factors affecting how often to make a fresh full
    // backup:
    // 1) The longer we wait, the more we're filling up the backend with 
    //    iterations on the same crap.
    // 2) The longer we wait, there's a higher risk that some bit will flip
    //    and the whole backup is toast.
    // 3) The longer we wait, the less annoying we are, since full backups 
    //    take a long time.
    // So we try to do them at reasonable times.  But almost nobody should be
    // going longer than 3 months without a full backup, and nobody should
    // really be making full backups shorter than a week.  Further, we want
    // to try to keep at least 2 full backups around, so also don't allow a
    // longer full threshold than half the delete age.
    // 
    // 'daily' gets 1 week 1 * 7
    // 'weekly' gets 6 weeks 7 * 6
    // 'biweekly' gets 12 weeks 14 * 6
    // 'monthly' gets 12 weeks 28 * 3
    var max = 12 * 7;
    var min = 1 * 7;
    
    var delete_age = client.get_int(DELETE_AFTER_KEY);
    if (delete_age > 0)
      max = int.min(delete_age/2, max);
    
    var periodic = client.get_bool(PERIODIC_KEY);
    if (periodic) {
      var period = client.get_int(PERIODIC_PERIOD_KEY);
      threshold = period * 6;
      threshold.clamp(min, max);
    }
    else
      threshold = max;
  }
  catch (Error e) {warning("%s\n", e.message);}
  
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

