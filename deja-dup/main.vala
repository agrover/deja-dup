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

extern unowned Resource resources_get_resource();

public class DejaDupApp : Gtk.Application
{
  Gtk.ApplicationWindow main_window = null;
  SimpleAction quit_action = null;
  public AssistantOperation op {get; private set; default = null;}

  const OptionEntry[] options = {
    {"version", 0, 0, OptionArg.NONE, null, N_("Show version"), null},
    {"restore", 0, 0, OptionArg.NONE, null, N_("Restore given files"), null},
    {"backup", 0, 0, OptionArg.NONE, null, N_("Immediately start a backup"), null},
    {"auto", 0, OptionFlags.HIDDEN, OptionArg.NONE, null, null, null},
    {"restore-missing", 0, 0, OptionArg.NONE, null, N_("Restore deleted files"), null},
    {"delay", 0, OptionFlags.HIDDEN, OptionArg.STRING, null, null, null},
    {"prompt", 0, OptionFlags.HIDDEN, OptionArg.NONE, null, null, null},
    {"", 0, 0, OptionArg.FILENAME_ARRAY, null, null, null}, // remaining
    {null}
  };

  const ActionEntry[] actions = {
    {"backup", backup},
    {"backup-auto", backup_auto},
    {"restore", restore},
    {"op-show", op_show},
    {"prompt-ok", prompt_ok},
    {"prompt-cancel", prompt_cancel},
    {"delay", delay, "s"},
    {"help", help},
    {"about", about},
    {"quit", quit},
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

    if (options.contains("restore")) {
      if (op != null) {
        command_line.printerr("%s\n", _("An operation is already in progress"));
        return 1;
      }

      List<File> file_list = new List<File>();
      if (filenames.length > 0) {
        int i = 0;
        while (filenames[i] != null)
          file_list.append(command_line.create_file_for_arg(filenames[i++]));
      }

      restore_full(file_list);
    }
    else if (options.contains("restore-missing")) {
      if (op != null) {
        command_line.printerr("%s\n", _("An operation is already in progress"));
        return 1;
      }

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
      assign_op(new AssistantRestoreMissing(list_directory));
    }
    else if (options.contains("backup")) {
      if (op != null) {
        command_line.printerr("%s\n", _("An operation is already in progress"));
        return 1;
      }

      backup_full(options.contains("auto"));
    }
    else if (options.contains("delay")) {
      string reason = null;
      options.lookup("delay", "s", ref reason);
      send_delay_notification(reason);
    }
    else if (options.contains("prompt")) {
      var toplevel = prompt(this);
      if (toplevel != null)
        add_window(toplevel);
    } else {
      activate();
    }

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
      main_window.destroy.connect(() => {this.main_window = null;});

      // Translators: "Backups" is a noun
      main_window.title = _("Backups");
      main_window.resizable = false;

      var header = new Gtk.HeaderBar();
      header.show_close_button = true;
      main_window.set_titlebar(header);

      var auto_switch = new DejaDup.PreferencesPeriodicSwitch();
      auto_switch.valign = Gtk.Align.CENTER;
      header.pack_end(auto_switch);

      var prefs = new DejaDup.Preferences();
      prefs.app = this;
      prefs.border_width = 12;
      main_window.add(prefs);
      add_window(main_window);
      main_window.show_all();
    }
  }

  public override void startup()
  {
    base.startup();

    /* First, check duplicity version info */
    if (!DejaDup.gui_initialize(null)) {
      quit();
      return;
    }

    add_action_entries(actions, this);
    set_accels_for_action("app.help", {"F1"});
    set_accels_for_action("app.quit", {"<Primary>q"});
    quit_action = lookup_action("quit") as SimpleAction;
  }

  void clear_op()
  {
    op = null;
    quit_action.set_enabled(true);
  }

  void assign_op(AssistantOperation op)
  {
    if (this.op != null) {
      warning("Trying to override operation! This shouldn't happen.");
      return;
    }

    this.op = op;
    this.op.destroy.connect(clear_op);
    quit_action.set_enabled(false);
    add_window(op);
    op.show_all();

    Gdk.notify_startup_complete();
  }

  public void delay(GLib.SimpleAction action, GLib.Variant? parameter)
  {
    string reason = null;
    parameter.get("s", ref reason);
    send_delay_notification(reason);
  }

  void send_delay_notification(string reason)
  {
    var note = new Notification(_("Scheduled backup delayed"));
    note.set_body(reason);
    note.set_icon(new ThemedIcon("org.gnome.DejaDup"));
    send_notification("backup-status", note);
  }

  void help()
  {
    unowned List<Gtk.Window> list = get_windows();
    DejaDup.show_uri(list == null ? null : list.data, "help:org.gnome.DejaDup");
  }

  void about()
  {
    unowned List<Gtk.Window> list = get_windows();
    Gtk.show_about_dialog(list == null ? null : list.data,
                          "license-type", Gtk.License.GPL_3_0,
                          "logo-icon-name", "org.gnome.DejaDup",
                          "translator-credits", _("translator-credits"),
                          "version", Config.VERSION,
                          "website", "https://wiki.gnome.org/Apps/DejaDup");
  }

  public void backup()
  {
    if (op != null) {
      op_show();
    } else {
      backup_full(false);
    }
  }

  public void backup_auto()
  {
    if (op == null) {
      backup_full(true);
    }
  }

  void backup_full(bool automatic)
  {
    assign_op(new AssistantBackup(automatic));
    // showing or not is handled by AssistantBackup
  }

  public void restore()
  {
    if (op != null) {
      op_show();
    } else {
      restore_full(null);
    }
  }

  void restore_full(List<File>? file_list)
  {
    assign_op(new AssistantRestore.with_files(file_list));
  }

  void op_show()
  {
    // Show op window if it exists, else just activate
    if (op != null)
      op.force_visible(true);
    else
      activate();
  }

  void prompt_ok()
  {
    prompt_cancel();
    activate();
  }

  void prompt_cancel()
  {
    DejaDup.update_prompt_time(true);
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
  Environment.set_prgname("org.gnome.DejaDup");

  Gtk.Window.set_default_icon_name("org.gnome.DejaDup");

  resources_get_resource()._register();

  return new DejaDupApp().run(args);
}
