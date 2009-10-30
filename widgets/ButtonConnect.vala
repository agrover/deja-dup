/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2009 Michael Terry <mike@mterry.name>

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

namespace DejaDup {

public class ButtonConnect : Gtk.Button
{
  construct {
    set("use-underline", true,
        "label", _("Connect to _Server…"));
    clicked.connect((b) => {run_connect_server_dialog(get_topwindow(this));});
  }
  
  public static void run_connect_server_dialog(Gtk.Window? parent)
  {
    try {
      Process.spawn_command_line_async("nautilus-connect-server");
    } catch (Error e) {
      var dlg = new Gtk.MessageDialog (parent, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, _("Could not open connection dialog"));
      dlg.format_secondary_text("%s", e.message);
      dlg.run();
      dlg.destroy();
    }
  }
}

}

