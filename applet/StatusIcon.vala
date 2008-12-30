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
  Notify.Notification note;
  bool need_passphrase;
  bool fatal_error;
  
  construct {
    icon_name = Config.PACKAGE;
    Idle.add(start_idle);
    popup_menu += show_menu;
  }
  
  ~StatusIcon()
  {
    if (note != null) {
      try {
        note.close();
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    }
  }
  
  void send_done(DejaDup.OperationBackup op, bool success)
  {
    done();
  }
  
  void set_action_desc(DejaDup.OperationBackup op, string action)
  {
    set_tooltip(action);
  }
  
  bool start_idle() {
    start(true);
    return false;
  }
  
  void start(bool warn)
  {
    need_passphrase = false;
    fatal_error = false;
    
    op = new DejaDup.OperationBackup(null);
    op.done += send_done;
    op.passphrase_required += notify_passphrase;
    op.backend_password_required += notify_backend_password;
    op.raise_error += notify_error;
    op.action_desc_changed += set_action_desc;
    
    if (warn)
      notify_start();
    else
      begin_backup();
  }
  
  void begin_backup() {
    try {
      op.start();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  void notify_start() {
    note = new Notify.Notification.with_status_icon(_("Backup about to start"),
                       _("A scheduled backup will shortly begin.  You can instead choose to backup later or not at all."),
                       Config.PACKAGE, this);
    note.add_action("skip", _("Skip Backup"), (Notify.ActionCallback)skip, this, null);
    note.add_action("later", _("Backup Later"), (Notify.ActionCallback)later, this, null);
    note.closed += begin_backup;
    try {
      note.show();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      begin_backup();
    }
  }
  
  bool notify_passphrase(DejaDup.OperationBackup op) {
    need_passphrase = true;
    set_blinking(true);
    activate += activate_enter;
    
    note = new Notify.Notification.with_status_icon(_("Encryption password needed"),
                       _("Please enter the encryption password for your backup files."),
                       "dialog-password", this);
    note.add_action("default", _("Enter"), (Notify.ActionCallback)enter, this, null);
    try {
      note.show();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    return false; // don't immediately ask user, wait for our response
  }
  
  bool notify_backend_password(DejaDup.OperationBackup op) {
    set_blinking(true);
    activate += activate_enter;
    
    note = new Notify.Notification.with_status_icon(_("Server password needed"),
                       _("Please enter the server password for your backup."),
                       "dialog-password", this);
    note.add_action("default", _("Enter"), (Notify.ActionCallback)enter, this, null);
    try {
      note.show();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    return false; // don't immediately ask user, wait for our response
  }
  
  void notify_error(DejaDup.OperationBackup op, string errstr, string? detail) {
    // TODO: Do something sane with detail.  Not urgent right now, it's only used for restore
    
    // We want to stay open until user acknowledges our error/it times out
    op.done -= send_done;
    fatal_error = true;
    note = new Notify.Notification.with_status_icon(_("Backup error occurred"),
                       errstr, "dialog-error", this);
    note.add_action("rerun", _("Rerun"), (Notify.ActionCallback)rerun, this, null);
    note.set_timeout(Notify.EXPIRES_NEVER);
    note.closed += error_closed;
    try {
      note.show();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  void end_notify(Notify.Notification? note) {
    set_blinking(false);
    activate -= activate_enter;
  }
  
  void error_closed(Notify.Notification note)
  {
    if (fatal_error)
      done();
  }
  
  static void enter(Notify.Notification? note, string? action, StatusIcon icon)
  {
    try {
      if (icon.need_passphrase) {
        icon.op.ask_passphrase();
        icon.need_passphrase = false;
      }
      else
        icon.op.ask_backend_password();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    icon.end_notify(note);
  }
  
  void activate_enter()
  {
    enter(note, null, this);
  }
  
  static void rerun(Notify.Notification? note, string? action, StatusIcon icon)
  {
    icon.fatal_error = false;
    icon.start(false);
  }
  
  static void later(Notify.Notification? note, string? action, StatusIcon icon)
  {
    icon.end_notify(note);
    icon.op.cancel();
  }
  
  static void skip(Notify.Notification? note, string? action, StatusIcon icon)
  {
    // Fake a run by setting today's timestamp as the 'last-run' gconf key
    try {
      DejaDup.update_last_run_timestamp();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    icon.end_notify(note);
    icon.op.cancel();
  }
  
  void show_menu(StatusIcon status_icon, uint button, uint activate_time)
  {
    var menu = new Gtk.Menu();
    
    Gtk.MenuItem item;
    
    item = new Gtk.MenuItem.with_mnemonic(_("Backup _Later"));
    item.activate += later_clicked;
    menu.append(item);
    
    item = new Gtk.MenuItem.with_mnemonic(_("_Skip Backup"));
    item.activate += skip_clicked;
    menu.append(item);
    
    item = new Gtk.SeparatorMenuItem();
    menu.append(item);
    
    item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_PREFERENCES, null);
    item.activate += preferences_clicked;
    menu.append(item);
    
    item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_ABOUT, null);
    item.activate += about_clicked;
    menu.append(item);
    
    menu.show_all();
    menu.popup(null, null, position_menu, button, activate_time);
  }
  
  void later_clicked(Gtk.MenuItem item) {
    later(note, null, this);
  }
  
  void skip_clicked(Gtk.MenuItem item) {
    skip(note, null, this);
  }
  
  void about_clicked(Gtk.MenuItem item) {
    DejaDup.show_about(this, null);
  }
  
  void preferences_clicked(Gtk.MenuItem item) {
    try {
      Process.spawn_command_line_async("deja-dup-preferences");
    }
    catch (Error e) {
      Gtk.MessageDialog dlg = new Gtk.MessageDialog (null, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, _("Could not open preferences"));
      dlg.format_secondary_text("%s", e.message);
      dlg.run();
      dlg.destroy();
    }
  }
}

