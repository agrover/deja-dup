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

class PreferencesApp : Gtk.Application
{
  public PreferencesApp()
  {
    Object(application_id: "org.gnome.DejaDup.Preferences");
  }

  public override void activate ()
  {
    base.activate();

    unowned List<Gtk.Window> list = get_windows();

    if (list != null)
      list.data.present_with_time(Gtk.get_current_event_time());
    else {
      // We're first instance.  Yay!

      var dlg = new Gtk.ApplicationWindow(this);
      // Translators: "Backups" is a noun
      dlg.title = _("Backups");
      dlg.resizable = false;

      var header = new Gtk.HeaderBar();
      header.show_close_button = true;
      dlg.set_titlebar(header);

      var auto_switch = new DejaDup.PreferencesPeriodicSwitch();
      auto_switch.valign = Gtk.Align.CENTER;
      header.pack_end(auto_switch);

      var prefs = new DejaDup.Preferences(auto_switch);
      prefs.border_width = 12;
      dlg.add(prefs);
      dlg.set_application(this);
      dlg.show_all();
    }
  }

  public override void startup ()
  {
    base.startup();

    add_action_entries(actions, null);

    var help = new Menu();
    help.append(_("_Help"), "app.help");
    var quit = new Menu();
    quit.append(_("_Quit"), "app.quit");
    var menu = new Menu();
    menu.append_section(null, help);
    menu.append_section(null, quit);
    set_app_menu(menu);
  }
}

PreferencesApp app = null;

bool show_version = false;
const OptionEntry[] options = {
  {"version", 0, 0, OptionArg.NONE, ref show_version, N_("Show version"), null},
  {null}
};

bool handle_console_options(out int status)
{
  status = 0;

  if (show_version) {
    print("%s %s\n", "deja-dup-preferences", Config.VERSION);
    return false;
  }

  return true;
}

const ActionEntry[] actions = {
  {"help", handle_help},
  {"quit", handle_quit},
};

void handle_help ()
{
  unowned List<Gtk.Window> list = app.get_windows();
  DejaDup.show_uri(list == null ? null : list.data, "help:deja-dup");
}

void handle_quit ()
{
  app.quit();
}

int main(string [] args)
{
  DejaDup.i18n_setup();

  Environment.set_application_name(_("Backups"));

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

  app = new PreferencesApp();
  return app.run();
}
