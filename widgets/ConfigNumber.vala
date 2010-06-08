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

public class ConfigNumber : ConfigWidget
{
  public int lower_bound {get; construct;}
  public int upper_bound {get; construct;}
  
  public ConfigNumber(string key, int lower_bound, int upper_bound)
  {
    Object(key: key, lower_bound: lower_bound, upper_bound: upper_bound);
  }
  
  Gtk.SpinButton spin;
  construct {
    spin = new Gtk.SpinButton.with_range(lower_bound, upper_bound, 1);
    add(spin);
    
    set_from_config();
    spin.value_changed.connect(handle_value_changed);
  }
  
  protected override async void set_from_config()
  {
    var val = settings.get_value(key).get_int32();
    spin.@value = val;
  }
  
  void handle_value_changed()
  {
    settings.set_value(key, new Variant.int32((int)spin.@value));
  }
}

}

