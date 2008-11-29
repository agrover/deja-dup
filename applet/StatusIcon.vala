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
    var note = new Notify.Notification.with_status_icon(_("Backup passphrase needed"),
                       _("Please enter the encryption passphrase for your backup files."),
                       "dialog-password", this);
    note.add_action("later", _("Ask Later"), (Notify.ActionCallback)later, this, null);
    note.add_action("skip", _("Skip Backup"), (Notify.ActionCallback)skip, this, null);
    note.add_action("enter", _("Enter"), (Notify.ActionCallback)enter, this, null);
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
}

