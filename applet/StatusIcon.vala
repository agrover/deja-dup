/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup Applet
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

public class StatusIcon : Gtk.StatusIcon
{
  public signal void done();
  
  DejaDup.OperationBackup op;
  construct {
    icon_name = Config.PACKAGE;
    Idle.add(start);
    popup_menu += show_menu;
  }
  
  bool start()
  {
    op = new DejaDup.OperationBackup(null);
    op.done += (b, s) => {done();};
    op.passphrase_required += notify_passphrase;
    
    try {
      op.start();
    }
    catch (Error e) {
      printerr("%s\n", e.message);
    }
    
    return false;
  }
  
  bool notify_passphrase(DejaDup.OperationBackup op) {
    var note = new Notify.Notification.with_status_icon(_("Backup password needed"),
                       _("Please enter the encryption password for your backup files."),
                       "dialog-password", this);
    note.add_action("later", _("Ask Later"), (Notify.ActionCallback)later, this, null);
    note.add_action("skip", _("Skip Backup"), (Notify.ActionCallback)skip, this, null);
    note.add_action("enter", _("Enter"), (Notify.ActionCallback)enter, this, null);
    note.add_action("default", _("Enter"), (Notify.ActionCallback)enter, this, null);
    note.closed += passphrase_closed;
    note.set_timeout(Notify.EXPIRES_NEVER);
    note.@ref();
    try {
      note.show();
    }
    catch (Error e) {
      printerr("%s\n", e.message);
    }
    return false; // don't immediately ask user, wait for our response
  }
  
  void passphrase_closed(Notify.Notification note) {
    later(note, "later", this);
  }
  
  static void enter(Notify.Notification note, string action, StatusIcon icon)
  {
    icon.op.ask_passphrase();
    note.unref();
  }
  
  static void later(Notify.Notification note, string action, StatusIcon icon)
  {
    print("later\n");
    note.unref();
  }
  
  static void skip(Notify.Notification note, string action, StatusIcon icon)
  {
    print("skip\n");
    note.unref();
  }
  
  void show_menu(Gtk.StatusIcon status_icon, uint button, uint activate_time)
  {
    var menu = new Gtk.Menu();
    
    var item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_PREFERENCES, null);
    item.activate += preferences_clicked;
    menu.append(item);
    
    item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_ABOUT, null);
    item.activate += about_clicked;
    menu.append(item);
    
    menu.show_all();
    // FIXME: We should be able to pass gtk_status_icon_position_menu function
    // to popup to position the menu correctly, but bug 562725
    // (http://bugzilla.gnome.org/show_bug.cgi?id=562725) is getting in the
    // way.
    menu.popup(null, null, null, button, activate_time);
  }
  
  void about_clicked(Gtk.ImageMenuItem item) {
    DejaDup.show_about(this, null);
  }
  
  void preferences_clicked(Gtk.ImageMenuItem item) {
    try {
      Process.spawn_command_line_async("deja-dup-preferences");
    }
    catch (Error e) {
      Gtk.MessageDialog dlg = new Gtk.MessageDialog (null, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, _("Could not open preferences"));
      dlg.format_secondary_text("%s".printf(e.message));
      dlg.run();
      dlg.destroy();
    }
  }
}

