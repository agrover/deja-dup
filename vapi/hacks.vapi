/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
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

[CCode (cheader_filename = "hacks.h")]
uint32 hacks_status_icon_get_x11_window_id (Gtk.StatusIcon icon);

[CCode (cheader_filename = "hacks.h")]
bool hacks_show_uri (string uri) throws GLib.Error;

[CCode (cheader_filename = "hacks.h")]
bool hacks_file_make_directory_with_parents (GLib.File file) throws GLib.Error;

[CCode (cheader_filename = "hacks.h")]
Gdk.Pixbuf hacks_get_icon_at_size (string name, int size) throws GLib.Error;

[CCode (cheader_filename = "hacks.h")]
GLib.FileType hacks_file_query_file_type (GLib.File file, GLib.FileQueryInfoFlags flags);

[CCode (cheader_filename = "hacks.h")]
string hacks_unix_mount_get_fs_type (string file);

[CCode (cheader_filename = "hacks.h")]
void hacks_status_icon_set_tooltip_text (Gtk.StatusIcon icon, string text);

[CCode (cheader_filename = "hacks.h")]
Gdk.Window hacks_widget_get_window (Gtk.Widget widget);

[CCode (cheader_filename = "hacks.h")]
GLib.MountOperation hacks_mount_operation_new (Gtk.Window parent);

[CCode (cheader_filename = "hacks.h")]
double hacks_adjustment_get_page_size (Gtk.Adjustment adjust);

[CCode (cheader_filename = "hacks.h")]
double hacks_adjustment_get_upper (Gtk.Adjustment adjust);

[CCode (cheader_filename = "hacks.h")]
weak Gtk.Widget hacks_dialog_get_action_area (Gtk.Dialog dialog);
