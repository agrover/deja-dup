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

using GLib;

namespace DejaDup {

public class ConfigEntry : ConfigWidget
{
  public ConfigEntry(string key)
  {
    Object(key: key);
  }
  
  Gtk.Entry entry;
  construct {
    entry = new Gtk.Entry();
    add(entry);
    
    set_from_config();
    entry.focus_out_event.connect(handle_focus_out);
  }
  
  protected override async void set_from_config()
  {
    try {
      var val = client.get_string(key);
      if (val == null)
        val = "";
      entry.set_text(val);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  bool handle_focus_out()
  {
    try {
      client.set_string(key, entry.get_text());
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    return false;
  }
}

}

