/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*- */
/*
    Déjà Dup
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

public class DuplicityInfo : Object
{
  public static const int required_major = 0;
  public static const int required_minor = 5;
  public static const int required_micro = 3;
  
  // Returns true if everything is OK.  If false, program will close.  A dialog
  // will already have been thrown up.
  public static bool check_duplicity_version(Gtk.Window parent) {
    string stdout;
    
    try {
      Process.spawn_command_line_sync("duplicity --version", out stdout, null, null);
    }
    catch (Error e) {
      show_missing_duplicity_error(parent, e.message);
      return false;
    }
    
    var tokens = stdout.split(" ", 2);
    if (tokens == null || tokens[0] == null || tokens[1] == null) {
      show_missing_duplicity_error(parent, null);
      return false;
    }
    
    // First token is 'duplicity' and is ignorable.  Second looks like '0.5.03'
    version_string = tokens[1].strip();
    var ver_tokens = version_string.split(".");
    if (ver_tokens == null || ver_tokens[0] == null) {
      show_missing_duplicity_error(parent, null);
      return false;
    }
    major = ver_tokens[0].to_int();
    if (ver_tokens[1] == null) {
      show_missing_duplicity_error(parent, null);
      return false;
    }
    minor = ver_tokens[1].to_int();
    if (ver_tokens[2] != null) // Don't error out if no micro.  Duplicity might not have one?
      micro = ver_tokens[2].to_int();
    
    var good_enough = meets_requirements();
    if (!good_enough) {
      show_bad_version_error(parent);
      return false;
    }
    return true;
  }
  
  static string version_string = null;
  static int major = 0;
  static int minor = 0;
  static int micro = 0;
  
  // Doesn't yet handle a blacklist of versions.  We'll cross that bridge when we come to it
  static bool meets_requirements() {
    return (major > required_major) ||
           (major == required_major && minor > required_minor) ||
           (major == required_major && minor == required_minor && micro >= required_micro);
  }
  
  static void show_missing_duplicity_error(Gtk.Window parent, string? msg_in) {
    Gtk.MessageDialog dlg = new Gtk.MessageDialog (parent,
        Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
        Gtk.MessageType.ERROR,
        Gtk.ButtonsType.OK,
        _("Could not run duplicity"));

    string msg = msg_in;
    if (msg != null)
      msg = msg.chomp() + "\n\n";
    else if (version_string == null)
        msg = _("Couldn't understand duplicity version");
    else
        msg = _("Couldn't understand duplicity version '%s'").printf(version_string);

    dlg.format_secondary_text("%s%s".printf(msg, _("Without duplicity, Déjà Dup cannot function.  It will close now.")));
    dlg.run();
    dlg.destroy();
    Gtk.main_quit();
  }
  
  static void show_bad_version_error(Gtk.Window parent) {
    Gtk.MessageDialog dlg = new Gtk.MessageDialog (parent,
        Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
        Gtk.MessageType.ERROR,
        Gtk.ButtonsType.OK,
        _("Duplicity's version is too old"));
    dlg.format_secondary_text(_("Déjà Dup requires at least version %d.%d.%.2d of duplicity, but only found version %d.%d.%.2d").printf(required_major, required_minor, required_micro, major, minor, micro));
    dlg.run();
    dlg.destroy();
    Gtk.main_quit();
  }
}

