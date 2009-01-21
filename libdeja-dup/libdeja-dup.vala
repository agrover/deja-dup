/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup Library
    © 2008—2009—2009 Michael Terry <mike@mterry.name>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
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

public void update_last_run_timestamp() throws Error
{
  TimeVal cur_time = TimeVal();
  cur_time.get_current_time();
  var cur_time_str = cur_time.to_iso8601();
  
  var client = GConf.Client.get_default();
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
    Gtk.show_uri (null, link, Gdk.CURRENT_TIME);
  } catch (Error e) {
    Gtk.MessageDialog dlg = new Gtk.MessageDialog (parent, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, _("Could not display %s"), link);
    dlg.format_secondary_text("%s", e.message);
    dlg.run ();
    dlg.destroy ();
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
const string[] authors = {"Michael Terry <mike@mterry.name>",
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
  about.translator_credits = _("translator-credits");
  about.logo_icon_name = Config.PACKAGE;
  about.version = Config.VERSION;
  about.copyright = "© 2008—2009 Michael Terry";
  about.website = "http://mterry.name/deja-dup/";
  about.license = "%s\n\n%s\n\n%s".printf (
    _("This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version."),
    _("This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details."),
    _("You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA."));
  about.wrap_license = true;
  
  owner.set_data("about-dlg", about);
  about.set_data("owner", owner);
  
  about.set_transient_for(parent);
  about.response += (dlg, resp) => {
    Object about_owner = (Object)dlg.get_data("owner");
    about_owner.set_data("about-dlg", null);
    dlg.destroy();
  };
  
  about.show();
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
    else
      bus.release_name("net.launchpad.deja-dup." + busname);
  }
  catch (Error e) {
    warning("%s\n", e.message);
  }
  
  return true;
}

} // end namespace

