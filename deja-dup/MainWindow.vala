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

public string get_restore_icon_filename() {
  return Path.build_filename(Config.PKG_DATA_DIR, "document-save.svg");
}

public string get_backup_icon_filename() {
  return Path.build_filename(Config.PKG_DATA_DIR, "document-send.svg");
}

public class MainWindow : Gtk.Window
{
  Gtk.Dialog progress;
  Gtk.ProgressBar progress_bar;
  Gtk.Label progress_label;
  uint timeout_id;
  
  DejaDup.Operation op;
  
  construct
  {
    Gtk.VBox vb = new Gtk.VBox (false, 0);
    
    var restore_align = new Gtk.Alignment(0.5f, 0.5f, 0.0f, 0.0f);
    
    var restore_button = new Gtk.Button();
    restore_button.set("child", restore_align);
    
    var restore_icon = new Gtk.Image();
    try {
      var filename = get_restore_icon_filename();
      var restore_pix = new Gdk.Pixbuf.from_file_at_size(filename, 128, 128);
      restore_icon.set("pixbuf", restore_pix);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    var restore_label = new Gtk.Label("_Restore");
    restore_label.set("use-underline", true,
                      "mnemonic-widget", restore_button);
    
    var restore_vbox = new Gtk.VBox(false, 0);
    restore_vbox.set("border-width", 12,
                     "child", restore_icon,
                     "child", restore_label);
    
    restore_align.add(restore_vbox);
    
    var backup_align = new Gtk.Alignment(0.5f, 0.5f, 0.0f, 0.0f);
    
    var backup_button = new Gtk.Button();
    backup_button.set("child", backup_align);
    
    var backup_icon = new Gtk.Image();
    try {
      var filename = get_backup_icon_filename();
      var backup_pix = new Gdk.Pixbuf.from_file_at_size(filename, 128, 128);
      backup_icon.set("pixbuf", backup_pix);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    var backup_label = new Gtk.Label("_Backup");
    backup_label.set("use-underline", true,
                     "mnemonic-widget", backup_button);
    
    var backup_vbox = new Gtk.VBox(false, 0);
    backup_vbox.set("border-width", 12,
                    "child", backup_icon,
                    "child", backup_label);
    
    backup_align.add(backup_vbox);
    
    var hbox = new Gtk.HBox(true, 12);
    hbox.set("border-width", 12,
             "child", restore_button,
             "child", backup_button);
    
    restore_button.clicked += (b) => {ask_restore();};
    backup_button.clicked += (b) => {do_backup();};
    
    vb.pack_start (setup_menu (), false, false, 0);
    vb.pack_start (hbox, true, true, 0);
    
    backup_button.grab_focus();
    
    add (vb);
    
    Idle.add(check_duplicity_version);
    
    destroy += Gtk.main_quit;
  }
  
  bool check_duplicity_version()
  {
    DejaDup.DuplicityInfo.get_default().check_duplicity_version(this);
    return false;
  }
  
  void show_success(string label, string desc)
  {
    var dlg = new Gtk.MessageDialog (toplevel, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "%s", label);
    dlg.format_secondary_text("%s", desc);
    dlg.run();
    dlg.destroy();
  }
  
  void show_error(DejaDup.Operation op, string errstr, string? detail)
  {
    hide_progress();
    
    var dlg = new Gtk.MessageDialog (toplevel, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, _("Error occurred"));
    dlg.format_secondary_text("%s", errstr);
    
    if (detail != null) {
      var error_buf = new Gtk.TextBuffer(null);
      error_buf.set_text(detail, -1);
      
      var error_view = new Gtk.TextView.with_buffer(error_buf);
      error_view.editable = false;
      error_view.wrap_mode = Gtk.WrapMode.WORD;
      
      var scroll = new Gtk.ScrolledWindow(null, null);
      scroll.add(error_view);
      
      var expander = new Gtk.Expander.with_mnemonic(_("_Details"));
      expander.add(scroll);
      
      expander.show_all();
      dlg.vbox.pack_start_defaults(expander);
    }
    
    dlg.run();
    dlg.destroy();
  }
  
  bool pulse()
  {
    progress_bar.pulse();
    return true;
  }
  
  void hide_progress()
  {
    if (timeout_id != 0)
      Source.remove(timeout_id);
    
    if (progress != null)
      progress.destroy();
    
    timeout_id = 0;
    progress = null;
  }
  
  void handle_progress_response(Gtk.Dialog dlg, int response)
  {
    if (response == Gtk.ResponseType.CANCEL) {
      op.cancel();
      // May take a bit, if we do a cleanup.  Mark cancel insensitive
      dlg.set_response_sensitive(response, false);
    }
  }
  
  void show_progress()
  {
    if (progress == null) {
      progress = new Gtk.Dialog.with_buttons("", this,
                                             Gtk.DialogFlags.MODAL |
                                             Gtk.DialogFlags.DESTROY_WITH_PARENT |
                                             Gtk.DialogFlags.NO_SEPARATOR,
                                             Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL);
      
      progress_label = new Gtk.Label("");
      progress_label.set("xalign", 0.0f);
      progress.vbox.add(progress_label);
      
      progress_bar = new Gtk.ProgressBar();
      progress.vbox.add(progress_bar);
      
      progress.response += handle_progress_response;
      
      timeout_id = Timeout.add(200, pulse);
      progress_bar.set_fraction(0); // Reset progress bar if this is second time we run this
      
      progress.show_all();
    }
  }
  
  void set_progress_label(DejaDup.Operation op, string action)
  {
    progress_label.set_text(action);
  }
  
  void on_backup(Gtk.Action action)
  {
    do_backup();
  }
  
  void do_backup()
  {
    show_progress();
    op = new DejaDup.OperationBackup(this);
    op.done += (b, s) => {
      hide_progress();
      op = null;
      if (s)
        show_success(_("Backup finished"), _("Your files were successfully backed up."));
    };
    op.raise_error += show_error;
    op.action_desc_changed += set_progress_label;
    
    try {
      op.start();
    }
    catch (Error e) {
      show_error(op, e.message, null);
    }
  }
  
  void on_restore(Gtk.Action action)
  {
    ask_restore();
  }
  
  void ask_restore()
  {
    var dlg = new RestoreAssistant();
    dlg.modal = true;
    dlg.transient_for = this;
    dlg.show_all();
  }
  
  void on_about(Gtk.Action action)
  {
    DejaDup.show_about(this, this);
  }
  
  void on_get_help(Gtk.Action action)
  {
    DejaDup.show_uri(this, "https://answers.launchpad.net/deja-dup");
  }
  
  void on_translate(Gtk.Action action)
  {
    DejaDup.show_uri(this, "https://translations.launchpad.net/deja-dup");
  }
  
  void on_report(Gtk.Action action)
  {
    DejaDup.show_uri(this, "https://bugs.launchpad.net/deja-dup/+filebug");
  }
  
  void on_preferences(Gtk.Action action)
  {
    try {
      Process.spawn_command_line_async("deja-dup-preferences");
    }
    catch (Error e) {
      Gtk.MessageDialog dlg = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, _("Could not open preferences"));
      dlg.format_secondary_text("%s", e.message);
      dlg.run();
      dlg.destroy();
    }
  }
  
  Gtk.Action backup_action;
  Gtk.Action restore_action;
  Gtk.Widget setup_menu ()
  {
    var action_group = new Gtk.ActionGroup ("actions");
    
    var action = new Gtk.Action ("FileMenuAction", _("_File"), null, null);
    action_group.add_action (action);
    
    action = new Gtk.Action ("BackupAction", _("_Backup"), null, null);
    //action.set("icon-name", "document-send");
    action.activate += on_backup;
    action_group.add_action_with_accel (action, "<control>B");
    this.backup_action = action;
    
    action = new Gtk.Action ("RestoreAction", _("_Restore"), null, null);
    //action.set("icon-name", "document-save");
    action.activate += on_restore;
    action_group.add_action_with_accel (action, "<control>R");
    this.restore_action = action;
    
    action = new Gtk.Action ("QuitAction", null, null, Gtk.STOCK_QUIT);
    action.activate += Gtk.main_quit;
    action_group.add_action_with_accel (action, "<control>Q");
    
    action = new Gtk.Action ("EditMenuAction", _("_Edit"), null, null);
    action_group.add_action (action);
    
    action = new Gtk.Action ("PreferencesAction", null, null, Gtk.STOCK_PREFERENCES);
    action.activate += on_preferences;
    action_group.add_action (action);
    
    action = new Gtk.Action ("HelpMenuAction", _("_Help"), null, null);
    action_group.add_action (action);
    
    action = new Gtk.Action ("GetHelpAction", _("Get Help _Online..."), null, null);
    action.activate += on_get_help;
    action_group.add_action (action);
    
    action = new Gtk.Action ("TranslateAction", _("_Translate This Application..."), null, null);
    action.activate += on_translate;
    action_group.add_action (action);
    
    action = new Gtk.Action ("ReportAction", _("_Report a Problem"), null, null);
    action.activate += on_report;
    action_group.add_action (action);
    
    action = new Gtk.Action ("AboutAction", null, null, Gtk.STOCK_ABOUT);
    action.activate += on_about;
    action_group.add_action (action);
    
    var ui = """
<ui>
  <menubar>
    <menu name="FileMenu" action="FileMenuAction">
      <menuitem name="Backup" action="BackupAction" />
      <menuitem name="Restore" action="RestoreAction" />
      <separator />
      <menuitem name="Quit" action="QuitAction" />
    </menu>
    <menu name="EditMenu" action="EditMenuAction">
      <menuitem name="Preferences" action="PreferencesAction"/>
    </menu>
    <menu name="HelpMenu" action="HelpMenuAction">
      <menuitem name="GetHelp" action="GetHelpAction"/>
      <menuitem name="Translate" action="TranslateAction"/>
      <menuitem name="Report" action="ReportAction"/>
      <separator/>
      <menuitem name="About" action="AboutAction"/>
    </menu>
  </menubar>
</ui>""";

    var manager = new Gtk.UIManager ();
    try {
    manager.add_ui_from_string (ui, ui.size ());
    } catch (Error e)  {
      error ("Internal error: bad ui string.\n");
    }
    manager.insert_action_group (action_group, 0);
    add_accel_group (manager.get_accel_group ());
    
    return manager.get_widget ("/ui/menubar");
  }
}

