/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008–2010 Michael Terry <mike@mterry.name>

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

[CCode (cheader_filename = "whacks.h")]
GLib.Object hacks_status_icon_make_app_indicator (Gtk.Menu menu);

[CCode (cheader_filename = "whacks.h")]
void hacks_status_icon_close_app_indicator (GLib.Object icon);

[CCode (cheader_filename = "whacks.h")]
Gtk.ComboBox hacks_combo_box_text_new();

[CCode (cheader_filename = "whacks.h")]
string hacks_combo_box_get_text(Gtk.ComboBox box);

[CCode (cheader_filename = "whacks.h")]
long hacks_window_get_xid(Gdk.Window win);

[CCode (cheader_filename = "whacks.h")]
int hacks_widget_get_allocated_width(Gtk.Widget w);

[CCode (cheader_filename = "whacks.h")]
void hacks_widget_destroy(Gtk.Widget w);

[CCode (cheader_filename = "whacks.h")]
void hacks_quit_on_destroy(Gtk.Widget w);

[CCode (cheader_filename = "whacks.h")]
void hacks_get_natural_size(Gtk.Widget w, out Gtk.Requisition req);
