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

public class ConfigChoice : ConfigWidget
{
  public signal void changed(string val);
  
  protected Gtk.ComboBox combo;
  construct {
    combo = new Gtk.ComboBox.text();
    add(combo);
  }
  
  // Subclasses use this to setup the choice list
  protected int gconf_col;
  public void init(Gtk.TreeModel model, int gconf_col)
  {
    combo.model = model;
    this.gconf_col = gconf_col;
    
    combo.changed += handle_changed;
    
    set_from_config();
  }
  
  public Value? get_current_value()
  {
    Gtk.TreeIter iter;
    if (combo.get_active_iter(out iter)) {
      Value val;
      combo.model.get_value(iter, gconf_col, out val);
      return val;
    }
    return null;
  }
  
  protected virtual void handle_changed()
  {
    Value? val = get_current_value();
    string strval = val == null ? "" : val.get_string();
    
    try {
        client.set_string(key, strval);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    changed(strval);
  }
  
  protected override void set_from_config()
  {
    string confval;
    try {
        confval = client.get_string(key);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return;
    }
    
    bool valid;
    Gtk.TreeIter iter;
    valid = combo.model.get_iter_first(out iter);
    
    while (valid) {
      Value val;
      combo.model.get_value(iter, gconf_col, out val);
      string strval = val.get_string();
      
      if (strval == confval) {
        combo.set_active_iter(iter);
        break;
      }
      valid = combo.model.iter_next(ref iter);
    }
  }
}

