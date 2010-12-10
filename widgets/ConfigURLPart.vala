/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2010 Michael Terry <mike@mterry.name>

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

public class ConfigURLPart : ConfigEntry
{
  public enum Part {
    SERVER, PORT, USER, FOLDER
  }
  public Part part {get; construct;}

  public ConfigURLPart(Part part, string key, string ns="") {
    Object(key: key, ns: ns, part: part);
  }

  protected override async void set_from_config()
  {
    var val = settings.get_string(key);
    if (val == null)
      val = "";

    var uri = deja_dup_decode_uri(val);

    string text = "";

    switch (part) {
    case Part.SERVER:
      text = uri.host;
      break;
    case Part.PORT:
      if (uri.port >= 0)
        text = uri.port.to_string();
      break;
    case Part.FOLDER:
      text = uri.path;
      break;
    case Part.USER:
      text = uri.userinfo;
      break;
    }

    entry.set_text(text);
  }

  protected override void write_to_config()
  {
    var val = settings.get_string(key);
    if (val == null)
      val = "";
    var uri = deja_dup_decode_uri(val);

    var userval = entry.get_text();

    switch (part) {
    case Part.SERVER:
      uri.host = userval;
      break;
    case Part.PORT:
      uri.port = userval.to_int();
      if (uri.port == 0) // no one would really want 0, right?
        uri.port = -1;
      break;
    case Part.FOLDER:
      uri.path = userval;
      break;
    case Part.USER:
      uri.userinfo = userval;
      break;
    }

    val = deja_dup_encode_uri(uri, true);
    settings.set_string(key, val);
  }
}

}

