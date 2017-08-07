/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
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

/* goabackend-1.0 does not ship a vapi... */
[CCode (cprefix = "Goa", gir_namespace = "Goa", gir_version = "1.0", lower_case_cprefix = "goa_")]
namespace Goa {
	[CCode (cheader_filename = "goabackend/goabackend.h", type_id = "goa_provider_get_type ()")]
	public class Provider : GLib.Object {
		[CCode (cname = "goa_provider_get_all")]
		public static async bool get_all ([CCode (pos = 0)] out GLib.List<Goa.Provider> providers) throws GLib.Error;
    public static Provider get_for_provider_type (string type);
    public unowned string get_provider_type ();
    public string get_provider_name (Goa.Object? object);
    public GLib.Icon get_provider_icon (Goa.Object? object);
    public ProviderFeatures get_provider_features ();
	}

	[CCode (cprefix = "GOA_PROVIDER_FEATURE_")]
	[Flags]
	public enum ProviderFeatures {
    BRANDED,
    MAIL,
    CALENDAR,
    CONTACTS,
    CHAT,
    DOCUMENTS,
    PHOTOS,
    FILES,
    TICKETING,
    READ_LATER,
    PRINTERS,
    MAPS,
    MUSIC,
  }
}
