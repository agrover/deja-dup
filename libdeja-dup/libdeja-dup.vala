/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup Library
    © 2008 Michael Terry <mike@mterry.name>

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
    dlg.format_secondary_text("%s".printf(e.message));
    dlg.run ();
    dlg.destroy ();
  }
}

} // end namespace

