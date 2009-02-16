/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup Applet
    © 2008—2009 Michael Terry <mike@mterry.name>

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

class DejaDupApplet : Object
{
  static bool show_version = false;
  static const OptionEntry[] options = {
    {"version", 0, 0, OptionArg.NONE, ref show_version, N_("Show version"), null},
    {null}
  };
  
  static bool handle_console_options(out int status)
  {
    status = 0;
    
    if (show_version) {
      print("%s %s\n", _("Déjà Dup Applet"), Config.VERSION);
      return false;
    }
    
    return true;
  }
  
  public static int main(string [] args)
  {
    GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);
    GLib.Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALE_DIR);
    GLib.Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    
    // Translators: 'Applet' in the sense of a notification area icon
    GLib.Environment.set_application_name(_("Déjà Dup Applet"));
    
    OptionContext context = new OptionContext("");
    context.add_main_entries(options, Config.GETTEXT_PACKAGE);
    context.add_group(Gtk.get_option_group(false)); // allow console use
    try {
      context.parse(ref args);
    } catch (Error e) {
      printerr("%s\n\n%s", e.message, context.get_help(true, null));
      return 1;
    }
    
    int status;
    if (!handle_console_options(out status))
      return status;
    
    Gtk.init(ref args); // to open display ('cause we passed false above)
    Notify.init(Environment.get_application_name());
    
    Gtk.IconTheme.get_default().append_search_path(Config.THEME_DIR);
    Gtk.Window.set_default_icon_name(Config.PACKAGE);
    
    DejaDup.DuplicityInfo.get_default().check_duplicity_version(null);
    
    // Try to claim bus, else don't run.  If the regularly scheduled backup
    // occurs while user is doing a manual backup, we don't want to run.
    // We'll try again the next day.
    if (DejaDup.set_bus_claimed("operation", true)) {
      var icon = new StatusIcon();
      icon.done += Gtk.main_quit;
      
      Gtk.main();
      
      DejaDup.set_bus_claimed("operation", false);
      return 0;
    }
    else
      return 1;
  }
}

