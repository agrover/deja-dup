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

public class ConfigChoice : ConfigWidget
{
  public signal void choice_changed(string val);
  
  protected Gtk.ComboBox combo;
  protected string default_val = null;
  construct {
    combo = new Gtk.ComboBoxText();
    add(combo);
  }
  
  // Subclasses use this to setup the choice list
  protected int settings_col;
  public void init(Gtk.TreeModel model, int settings_col)
  {
    combo.model = model;
    this.settings_col = settings_col;

    set_from_config.begin();
    combo.changed.connect(handle_changed);
  }
  
  public Value? get_current_value()
  {
    Gtk.TreeIter iter;
    if (combo.get_active_iter(out iter)) {
      Value val;
      combo.model.get_value(iter, settings_col, out val);
      return val;
    }
    return null;
  }
  
  protected virtual void handle_changed()
  {
    Value? val = get_current_value();
    string strval = val == null ? "" : val.get_string();
    
    settings.set_string(key, strval);
    
    choice_changed(strval);
  }
  
  protected override async void set_from_config()
  {
    string confval = settings.get_string(key);
    if (confval == null || confval == "")
      confval = default_val;
    if (confval == null)
      return;
    
    bool valid;
    Gtk.TreeIter iter;
    valid = combo.model.get_iter_first(out iter);
    
    while (valid) {
      Value val;
      combo.model.get_value(iter, settings_col, out val);
      string strval = val.get_string();
      
      if (strval == confval) {
        combo.set_active_iter(iter);
        break;
      }
      valid = combo.model.iter_next(ref iter);
    }
  }
}

}

