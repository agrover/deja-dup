/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2011 Michael Terry <mike@mterry.name>
    © 2011 Canonical Ltd

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

[CCode (cheader_filename = "whacks.h")]
bool hacks_unity_present();

[CCode (cheader_filename = "whacks.h")]
Object hacks_unity_get_entry();

[CCode (cheader_filename = "whacks.h")]
void hacks_unity_entry_show_progress(Object entry, bool show);

[CCode (cheader_filename = "whacks.h")]
void hacks_unity_entry_set_progress(Object entry, double percent);

[CCode (cheader_filename = "whacks.h")]
void hacks_unity_entry_set_menu(Object entry, Gtk.Menu? menu);
