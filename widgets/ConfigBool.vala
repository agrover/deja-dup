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

public class ConfigBool : ConfigWidget, Togglable
{
  public string label {get; construct;}
  
  public ConfigBool(string key, string label)
  {
    Object(key: key, label: label);
  }
  
  public bool get_active() {return button.get_active();}
  
  Gtk.CheckButton button;
  construct {
    button = new Gtk.CheckButton.with_mnemonic(label);
    add(button);
    
    set_from_config();
    button.toggled.connect(handle_toggled);
  }
  
  protected override void set_from_config()
  {
    try {
      var val = client.get_bool(key);
      button.set_active(val);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  void handle_toggled()
  {
    try {
      client.set_bool(key, button.get_active());
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    toggled();
  }
}

}

