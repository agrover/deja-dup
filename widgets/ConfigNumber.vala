/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008,2009 Michael Terry <mike@mterry.name>

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

public class ConfigNumber : ConfigWidget
{
  public int lower_bound {get; construct;}
  public int upper_bound {get; construct;}
  
  public ConfigNumber(string key, int lower_bound, int upper_bound)
  {
    this.key = key;
    this.lower_bound = lower_bound;
    this.upper_bound = upper_bound;
  }
  
  Gtk.SpinButton spin;
  construct {
    spin = new Gtk.SpinButton.with_range(lower_bound, upper_bound, 1);
    add(spin);
    
    set_from_config();
    spin.value_changed.connect(handle_value_changed);
  }
  
  protected override void set_from_config()
  {
    try {
      var val = client.get_int(key);
      spin.@value = val;
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  void handle_value_changed()
  {
    try {
      client.set_int(key, (int)spin.@value);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
}

}
