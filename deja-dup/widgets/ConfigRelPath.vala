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

using GLib;

namespace DejaDup {

public class ConfigRelPath : ConfigEntry
{
  public ConfigRelPath(string key, string ns="")
  {
    Object(key: key, ns: ns);
  }

  protected override async void set_from_config()
  {
    var byte_val = settings.get_value(key);
    string val = null;
    try {
      val = Filename.to_utf8(byte_val.get_bytestring(), -1, null, null);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    if (val == null)
      val = "";
    entry.set_text(val);
  }

  public override void write_to_config()
  {
    var val = new Variant.bytestring(entry.get_text());
    settings.set_value(key, val);
  }
}

}

