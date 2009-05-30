/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008,2009 Michael Terry <mike@mterry.name>

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

public class MainWindow : Gtk.Window
{
  construct
  {
    Gtk.VBox vb = new Gtk.VBox (false, 0);
    
    this.title = _("Déjà Dup");
    
    var restore_align = new Gtk.Alignment(0.5f, 0.5f, 0.0f, 0.0f);
    
    var restore_button = new Gtk.Button();
    restore_button.set("child", restore_align);
    
    var restore_icon = new Gtk.Image();
    try {
      var restore_pix = hacks_get_icon_at_size("deja-dup-restore", 128);
      restore_icon.set("pixbuf", restore_pix);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    var restore_label = new Gtk.Label(_("_Restore"));
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
      var backup_pix = hacks_get_icon_at_size("deja-dup-backup", 128);
      backup_icon.set("pixbuf", backup_pix);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    var backup_label = new Gtk.Label(_("_Backup"));
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
    
    restore_button.clicked.connect((b) => {ask_restore();});
    backup_button.clicked.connect((b) => {ask_backup();});
    
    vb.pack_start (setup_menu (), false, false, 0);
    vb.pack_start (hbox, true, true, 0);
    
    backup_button.grab_focus();
    
    add (vb);
    
    Idle.add(check_duplicity_version);
    
    destroy.connect(Gtk.main_quit);
  }
  
  bool check_duplicity_version()
  {
    DejaDup.DuplicityInfo.get_default().check_duplicity_version(this);
    return false;
  }
  
  void on_backup(Gtk.Action action)
  {
    ask_backup();
  }
  
  void ask_backup()
  {
    var dlg = new AssistantBackup();
    dlg.modal = true;
    dlg.transient_for = this;
    dlg.show_all();
  }
  
  void on_restore(Gtk.Action action)
  {
    ask_restore();
  }
  
  void ask_restore()
  {
    var dlg = new AssistantRestore();
    dlg.modal = true;
    dlg.transient_for = this;
    dlg.show_all();
  }
  
  void on_about(Gtk.Action action)
  {
    DejaDup.show_about(this, this);
  }
  
  void on_contents(Gtk.Action action)
  {
    DejaDup.show_uri(this, "ghelp:deja-dup");
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
    action.set("icon-name", "deja-dup-backup");
    action.activate.connect(on_backup);
    action_group.add_action_with_accel (action, "<control>B");
    this.backup_action = action;
    
    action = new Gtk.Action ("RestoreAction", _("_Restore"), null, null);
    action.set("icon-name", "deja-dup-restore");
    action.activate.connect(on_restore);
    action_group.add_action_with_accel (action, "<control>R");
    this.restore_action = action;
    
    action = new Gtk.Action ("QuitAction", null, null, Gtk.STOCK_QUIT);
    action.activate.connect(Gtk.main_quit);
    action_group.add_action_with_accel (action, "<control>Q");
    
    action = new Gtk.Action ("EditMenuAction", _("_Edit"), null, null);
    action_group.add_action (action);
    
    action = new Gtk.Action ("PreferencesAction", null, null, Gtk.STOCK_PREFERENCES);
    action.activate.connect(on_preferences);
    action_group.add_action (action);
    
    action = new Gtk.Action ("HelpMenuAction", _("_Help"), null, null);
    action_group.add_action (action);
    
    action = new Gtk.Action ("ContentsAction", _("_Contents"), null, Gtk.STOCK_HELP);
    action.activate.connect(on_contents);
    action_group.add_action_with_accel (action, "F1");
    
    action = new Gtk.Action ("GetHelpAction", _("Get Help _Online..."), null, null);
    action.activate.connect(on_get_help);
    action_group.add_action (action);
    
    action = new Gtk.Action ("TranslateAction", _("_Translate This Application..."), null, null);
    action.activate.connect(on_translate);
    action_group.add_action (action);
    
    action = new Gtk.Action ("ReportAction", _("_Report a Problem..."), null, null);
    action.activate.connect(on_report);
    action_group.add_action (action);
    
    action = new Gtk.Action ("AboutAction", null, null, Gtk.STOCK_ABOUT);
    action.activate.connect(on_about);
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
      <menuitem name="Contents" action="ContentsAction"/>
      <separator/>
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

