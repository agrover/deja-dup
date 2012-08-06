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

public class ConfigEntry : ConfigWidget
{
  public ConfigEntry(string key, string ns="")
  {
    Object(key: key, ns: ns);
  }
  
  public string get_text()
  {
    return entry.get_text();
  }

  public void set_accessible_name (string name)
  {
    var accessible = entry.get_accessible();
    if (accessible != null)
      accessible.set_name(name);
  }

  protected Gtk.Entry entry;
  construct {
    entry = new Gtk.Entry();
    add(entry);
    mnemonic_widget = entry;
    
    set_from_config.begin();
    entry.focus_out_event.connect(handle_focus_out);
  }

  protected override async void set_from_config()
  {
    var val = settings.get_string(key);
    if (val == null)
      val = "";
    entry.set_text(val);
  }

  public virtual void write_to_config()
  {
    settings.set_string(key, entry.get_text());
  }

  bool handle_focus_out()
  {
    write_to_config();
    return false;
  }
}

}

