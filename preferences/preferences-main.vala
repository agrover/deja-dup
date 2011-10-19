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

class PreferencesApp : Object
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
      print("%s %s\n", "deja-dup-preferences", Config.VERSION);
      return false;
    }

    return true;
  }

  static void activated (Gtk.Application app)
  {
    unowned List<Gtk.Window> list = app.get_windows();

    if (list != null)
      list.data.present_with_time(Gtk.get_current_event_time());
    else {
      // We're first instance.  Yay!
      var dlg = new Gtk.Window();
      // Translators: "Backup" is a noun
      dlg.title = _("Backup");
      dlg.resizable = false;
      var prefs = new DejaDup.Preferences();
      prefs.border_width = 12;
      dlg.add(prefs);
      dlg.set_application(app);
      dlg.show_all();
    }
  }

  public static int main(string [] args)
  {
    DejaDup.i18n_setup();

    Environment.set_application_name(_("Backup"));

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
    Gtk.IconTheme.get_default().append_search_path(Config.THEME_DIR);
    Gtk.Window.set_default_icon_name(Config.PACKAGE);

    if (!DejaDup.gui_initialize(null))
      return 1;

    var app = new Gtk.Application("org.gnome.DejaDup.Preferences", 0);
    app.activate.connect((app) => {activated(app as Gtk.Application);});
    return app.run();
  }
}

