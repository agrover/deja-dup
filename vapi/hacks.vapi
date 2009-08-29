/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008 Michael Terry <mike@mterry.name>

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

[CCode (cheader_filename = "hacks.h")]
string hacks_unix_mount_get_fs_type (string file);

[CCode (cheader_filename = "hacks.h")]
void hacks_status_icon_set_tooltip_text (Gtk.StatusIcon icon, string text);

[CCode (cheader_filename = "hacks.h")]
Gtk.Label hacks_make_link_label (string text);

[CCode (cprefix = "G", lower_case_cprefix = "g_", cheader_filename = "glib.h")]
namespace GLib {
	public class ParamSpecString : ParamSpec {
		[CCode (cname = "g_param_spec_string")]
		public ParamSpecString (string name, string nick, string blurb, string default_value, ParamFlags flags);
	}
}
