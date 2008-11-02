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

public class MainWindow : Gtk.Window
{
  Gtk.AboutDialog about;
  Gtk.Dialog preferences;
  
  construct
  {
    Gtk.VBox vb = new Gtk.VBox (false, 0);
    
    var restore_align = new Gtk.Alignment(0.5f, 0.5f, 0.0f, 0.0f);
    
    var restore_button = new Gtk.Button();
    restore_button.set("child", restore_align);
    
    var restore_icon = new Gtk.Image();
    try {
      var filename = "%s/document-save.svg".printf(Config.PKG_DATA_DIR);
      var restore_pix = new Gdk.Pixbuf.from_file_at_size(filename, 128, 128);
      restore_icon.set("pixbuf", restore_pix);
    }
    catch (Error e) {
      printerr("%s\n", e.message);
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
      var filename = "%s/document-send.svg".printf(Config.PKG_DATA_DIR);
      var backup_pix = new Gdk.Pixbuf.from_file_at_size(filename, 128, 128);
      backup_icon.set("pixbuf", backup_pix);
    }
    catch (Error e) {
      printerr("%s\n", e.message);
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
    
    restore_button.clicked += (b) => {do_restore();};
    backup_button.clicked += (b) => {do_backup();};
    
    vb.pack_start (setup_menu (), false, false, 0);
    vb.pack_start (hbox, true, true, 0);
    
    backup_button.grab_focus();
    
    add (vb);
    
    destroy += Gtk.main_quit;
  }
  
  void show_success(string label, string desc)
  {
    var dlg = new Gtk.MessageDialog (toplevel, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "%s", label);
    dlg.format_secondary_text("%s".printf(desc));
    dlg.run();
    dlg.destroy();
  }
  
  void on_backup(Gtk.Action action)
  {
    do_backup();
  }
  
  void do_backup()
  {
    var back = new OperationBackup();
    back.@ref();
    back.done += (b, s) => {
      b.unref();
      if (s)
        show_success(_("Backup finished"), _("Your files were successfully backed up."));
    };
    
    try {
      back.start();
    }
    catch (Error e) {
      printerr("%s\n", e.message);
    }
  }
  
  void on_restore(Gtk.Action action)
  {
    do_restore();
  }
  
  void do_restore()
  {
    var rest = new OperationRestore();
    rest.@ref();
    rest.done += (b, s) => {
      b.unref();
      if (s)
        show_success(_("Restore finished"), _("Your files were successfully restored."));
    };
    
    try {
      rest.start();
    }
    catch (Error e) {
      printerr("%s\n", e.message);
    }
  }
  
  void handle_about_uri(Gtk.AboutDialog about, string link)
  {
    show_uri(about, link);
  }
  
  void handle_about_mail(Gtk.AboutDialog about, string link)
  {
    show_uri(about, "mailto:%s".printf(link));
  }
  
  // These need to be class-wide to prevent an odd compiler syntax error.
  static const string[] authors = {"Michael Terry <mike@mterry.name>",
                                   null};

  void on_about(Gtk.Action action)
  {
    if (about != null)
    {
      about.present ();
      return;
    }

    about = new Gtk.AboutDialog ();
    about.set_email_hook (handle_about_mail, null);
    about.set_url_hook (handle_about_uri, null);
    about.title = _("About Déjà Dup");
    about.authors = authors;
    about.translator_credits = _("translator-credits");
    about.logo_icon_name = Config.PACKAGE;
    about.version = Config.VERSION;
    about.copyright = "© 2008 Michael Terry";
    about.website = "http://mterry.name/deja-dup/";
    about.license = "%s\n\n%s\n\n%s".printf (
      _("This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version."),
      _("This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details."),
      _("You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA."));
    about.wrap_license = true;
    
    about.set_transient_for(this);
    about.response += (dlg, resp) => {dlg.destroy (); about = null;};
    
    about.show();
  }
  
  void on_preferences(Gtk.Action action)
  {
    if (preferences != null)
    {
      preferences.present ();
      return;
    }
    
    preferences = new PreferencesDialog();
    preferences.response += (dlg, resp) => {dlg.destroy(); preferences = null;};
    preferences.show_all();
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

