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

const ActionEntry[] actions = {
  {"help", handle_help},
  {"quit", handle_quit},
};

void handle_help()
{
  var app = Application.get_default() as Gtk.Application;
  unowned List<Gtk.Window> list = app.get_windows();
  DejaDup.show_uri(list == null ? null : list.data, "help:deja-dup");
}

void handle_quit()
{
  var app = Application.get_default() as Gtk.Application;
  app.quit();
}

class DejaDupApp : Gtk.Application
{
  Gtk.ApplicationWindow main_window = null;
  const OptionEntry[] options = {
    {"version", 0, 0, OptionArg.NONE, null, N_("Show version"), null},
    {"restore", 0, 0, OptionArg.NONE, null, N_("Restore given files"), null},
    {"backup", 0, 0, OptionArg.NONE, null, N_("Immediately start a backup"), null},
    {"auto", 0, OptionFlags.HIDDEN, OptionArg.NONE, null, null, null},
    {"restore-missing", 0, 0, OptionArg.NONE, null, N_("Restore deleted files"), null},
    {"prompt", 0, OptionFlags.HIDDEN, OptionArg.NONE, null, null, null},
    {"", 0, 0, OptionArg.FILENAME_ARRAY, null, null, null}, // remaining
    {null}
  };
  
  public DejaDupApp()
  {
    Object(application_id: "org.gnome.DejaDup",
           flags: ApplicationFlags.HANDLES_COMMAND_LINE);
    add_main_option_entries(options);
  }

  public override int handle_local_options(VariantDict options)
  {
    if (options.contains("version")) {
      print("%s %s\n", "deja-dup", Config.VERSION);
      return 0;
    }
    return -1;
  }

  public override int command_line(ApplicationCommandLine command_line)
  {
    var options = command_line.get_options_dict();

    string[] filenames = {};
    if (options.contains("")) {
      var variant = options.lookup_value("", VariantType.BYTESTRING_ARRAY);
      filenames = variant.get_bytestring_array();
    }

    Gtk.Window toplevel = null;

    if (options.contains("restore")) {
      List<File> file_list = new List<File>();
      if (filenames != null) {
        int i = 0;
        while (filenames[i] != null)
          file_list.append(command_line.create_file_for_arg(filenames[i++]));
      }
      else {
        /* Determine if we should be in read-only mode.  This is done when
           we're asked to do a generic restore and the user has backed up
           before.  We do this because they may want to restore from a
           different backup without adjusting their own settings. */
        var last_run = DejaDup.last_run_date(DejaDup.TimestampType.BACKUP);
        if (last_run != "")
          DejaDup.set_settings_read_only(true);
      }
      toplevel = new AssistantRestore.with_files(file_list);
      toplevel.show_all();
    }
    else if (options.contains("backup")) {
      bool automatic = options.contains("auto");
      toplevel = new AssistantBackup(automatic);
      Gdk.notify_startup_complete();
      // showing or not is handled by AssistantBackup
    }
    else if (options.contains("restore-missing")) {
      if (filenames.length == 0) {
        command_line.printerr("%s\n", _("No directory provided"));
        return 1;
      }
      else if (filenames.length > 1) {
        command_line.printerr("%s\n", _("Only one directory can be shown at once"));
        return 1;
      }

      File list_directory = command_line.create_file_for_arg(filenames[0]);
      if (!list_directory.query_exists(null)) {
        command_line.printerr("%s\n", _("Directory does not exist"));
        return 1;
      }
      if (list_directory.query_file_type (0, null) != FileType.DIRECTORY) {
        command_line.printerr("%s\n", _("You must provide a directory, not a file"));
        return 1;
      }
      toplevel = new AssistantRestoreMissing(list_directory);
      toplevel.show_all();
    }
    else if (options.contains("prompt")) {
      toplevel = prompt();
    } else {
      activate();
    }

    if (toplevel != null)
      add_window(toplevel);

    return 0;
  }

  public override void activate()
  {
    base.activate();

    if (main_window != null)
      main_window.present_with_time(Gtk.get_current_event_time());
    else {
      // We're first instance.  Yay!

      main_window = new Gtk.ApplicationWindow(this);
      // Translators: "Backups" is a noun
      main_window.title = _("Backups");
      main_window.resizable = false;

      var header = new Gtk.HeaderBar();
      header.show_close_button = true;
      main_window.set_titlebar(header);

      var auto_switch = new DejaDup.PreferencesPeriodicSwitch();
      auto_switch.valign = Gtk.Align.CENTER;
      header.pack_end(auto_switch);

      var prefs = new DejaDup.Preferences(auto_switch);
      prefs.border_width = 12;
      main_window.add(prefs);
      main_window.show_all();
    }
  }

  public override void startup()
  {
    base.startup();

    Gtk.IconTheme.get_default().append_search_path(Config.THEME_DIR);
    Gtk.Window.set_default_icon_name(Config.PACKAGE);

    /* First, check duplicity version info */
    if (!DejaDup.gui_initialize(null)) {
      quit();
      return;
    }

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

int main(string[] args)
{
  DejaDup.i18n_setup();

  // Translators: The name is a play on the French phrase "déjà vu" meaning
  // "already seen", but with the "vu" replaced with "dup".  "Dup" in this
  // context is itself a reference to both the underlying command line tool
  // "duplicity" and the act of duplicating data for backup.  As a whole, the
  // phrase "Déjà Dup" may not be very translatable.
  Environment.set_application_name(_("Déjà Dup Backup Tool"));

  return new DejaDupApp().run(args);
}
