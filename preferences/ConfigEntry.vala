/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008—2009 Michael Terry <mike@mterry.name>

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

using GLib;

public class ConfigEntry : ConfigWidget
{
  public ConfigEntry(string key)
  {
    this.key = key;
  }
  
  Gtk.Entry entry;
  construct {
    entry = new Gtk.Entry();
    add(entry);
    
    set_from_config();
    entry.focus_out_event += handle_focus_out;
  }
  
  protected override void set_from_config()
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

