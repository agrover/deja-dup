/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2009 Michael Terry <mike@mterry.name>

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

namespace DejaDup {

public class ConfigLabel : ConfigWidget
{
  public ConfigLabel(string key)
  {
    this.key = key;
  }
  
  protected Gtk.Label label;
  construct {
    label = new Gtk.Label("");
    label.set("xalign", 0.0f);
    add(label);
    set_from_config();
  }
  
  protected override void set_from_config()
  {
    string val;
    try {
      val = client.get_string(key);
      label.label = val;
    }
    catch (Error e) {warning("%s\n", e.message);}
  }
}

}

