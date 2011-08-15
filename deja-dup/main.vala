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

public Gtk.Window toplevel = null;

class DejaDupApp : Object
{
  static bool show_version = false;
  static bool restore_mode = false;
  static bool backup_mode = false;
  static bool automatic = false;
  static bool restoremissing_mode = false;
  static bool prompt_mode = false;
  static string[] filenames = null;
  static const OptionEntry[] options = {
    {"version", 0, 0, OptionArg.NONE, ref show_version, N_("Show version"), null},
    {"restore", 0, 0, OptionArg.NONE, ref restore_mode, N_("Restore given files"), null},
    {"backup", 0, 0, OptionArg.NONE, ref backup_mode, N_("Immediately start a backup"), null},
    {"auto", 0, OptionFlags.HIDDEN, OptionArg.NONE, ref automatic, null, null},
    {"restore-missing", 0, 0, OptionArg.NONE, ref restoremissing_mode, N_("Restore deleted files"), null},
    {"prompt", 0, OptionFlags.HIDDEN, OptionArg.NONE, ref prompt_mode, null, null},
    {"", 0, 0, OptionArg.FILENAME_ARRAY, ref filenames, null, null}, // remaining
    {null}
  };
  
  static bool handle_console_options(out int status)
  {
    status = 0;
    
    if (show_version) {
      print("%s %s\n", "deja-dup", Config.VERSION);
      return false;
    }
    
    if (restoremissing_mode) {
      if (filenames == null) {
        printerr("%s\n", _("No directory provided"));
        status = 1;
        return false;
      }
      else if (filenames.length > 1) {
        printerr("%s\n", _("Only one directory can be shown at once"));
        status = 1;
        return false;
      }
    }
    
    return true;
  }

  public static int main(string [] args)
  {
    DejaDup.i18n_setup();

    // Translators: The name is a play on the French phrase "déjà vu" meaning
    // "already seen", but with the "vu" replaced with "dup".  "Dup" in this
    // context is itself a reference to both the underlying command line tool
    // "duplicity" and the act of duplicating data for backup.  As a whole, the
    // phrase "Déjà Dup" may not be very translatable.
    Environment.set_application_name(_("Déjà Dup Backup Tool"));
    
    var modes = "\n  %s --backup\n  %s --restore %s\n  %s --restore-missing %s"
                .printf(Config.PACKAGE, Config.PACKAGE, _("[FILES…]"),
                        Config.PACKAGE, _("DIRECTORY"));
    OptionContext context = new OptionContext(modes);

    // Translators: Wrap this to 80 characters per line if you can, as I have for English
    context.set_summary(_("Déjà Dup is a simple backup tool.  It hides the complexity of backing up\nthe Right Way (encrypted, off-site, and regular) and uses duplicity as\nthe backend."));
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

    /* First, check duplicity version info */
    if (!DejaDup.gui_initialize(null))
      return 1;

    /* Now proceed with main program */

    if (restore_mode) {
      List<File> file_list = new List<File>();
      if (filenames != null) {
        int i = 0;
        while (filenames[i] != null)
          file_list.append(File.new_for_commandline_arg(filenames[i++]));
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
    else if (backup_mode) {
      toplevel = new AssistantBackup(automatic);
      Gdk.notify_startup_complete();
      // showing or not is handled by AssistantBackup
    }
    else if (restoremissing_mode) {
      File list_directory = File.new_for_commandline_arg(filenames[0]);
      if (!list_directory.query_exists(null)) {
        printerr("%s\n", _("Directory does not exists"));
        return 1;
      }
      if (list_directory.query_file_type (0, null) != FileType.DIRECTORY) {
        printerr("%s\n", _("You must provide a directory, not a file"));
        return 1;
      }
      toplevel = new AssistantRestoreMissing(list_directory);
      toplevel.show_all();
    }
    else if (prompt_mode) {
      toplevel = prompt();
      if (toplevel == null)
        return 0; // we're already done
    }
    else {
        printerr("%s\n\n%s", _("You must specify a mode"), context.get_help(true, null));
        return 1;
    }

    toplevel.destroy.connect(Gtk.main_quit);

    Gtk.main();

    return 0;
  }
}

