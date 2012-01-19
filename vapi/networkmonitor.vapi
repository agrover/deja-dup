/* -*- Mode: Vala; indent-tabs-mode: t; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    For copyright information, see AUTHORS.

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

/**
 * vala-0.14 doesn't have vapi bindings for NetworkMonitor yet.
 * So here we add it ourselves.
 */

[CCode (cprefix = "G", gir_namespace = "Gio", gir_version = "2.0", lower_case_cprefix = "g_")]
namespace GLib {
	[CCode (cheader_filename = "gio/gio.h", cname = "GNetworkMonitor")]
	public class NetworkMonitor : GLib.Object {
		[CCode (has_construct_function = false)]
		protected NetworkMonitor ();
		public static unowned NetworkMonitor get_default ();
		public bool can_reach (GLib.SocketConnectable connectable, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public async bool can_reach_async (GLib.SocketConnectable connectable, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public bool network_available { get; }
		public virtual signal void network_changed (bool available);
	}
}
