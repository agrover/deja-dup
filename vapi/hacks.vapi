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

[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "chacks.h")]
public GnomeKeyring.PasswordSchema PASSPHRASE_SCHEMA;

[CCode (cheader_filename = "whacks.h")]
GLib.Object hacks_status_icon_make_app_indicator (Gtk.Menu menu);

[CCode (cheader_filename = "whacks.h")]
void hacks_status_icon_close_app_indicator (GLib.Object icon);

[CCode (cheader_filename = "uriutils.h", destroy_function = "deja_dup_decoded_uri_free")]
struct DejaDupDecodedUri {
  public DejaDupDecodedUri();
  public string scheme;
  public string userinfo;
  public string host;
  public int port; /* -1 => not in uri */
  public string path;
  public string query;
  public string fragment;
}

[CCode (cheader_filename = "uriutils.h")]
string       deja_dup_encode_uri                (DejaDupDecodedUri decoded,
                                                 bool allow_utf8);

[CCode (cheader_filename = "uriutils.h")]
DejaDupDecodedUri deja_dup_decode_uri          (string uri);

