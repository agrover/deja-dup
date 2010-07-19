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

public abstract class ConfigWidget : Gtk.EventBox
{
  public signal void changed();

  public string key {get; construct;}
  public string ns {get; construct; default = "";}
  
  List<string> watched_keys = null;
  protected Settings settings;
  construct {
    settings = DejaDup.get_settings(ns);
    
    if (key != null)
      watch_key(key);
  }
  
  protected void watch_key(string key)
  {
    // Wish we could use changed[key].connect to take advantage of detailed
    // signals, but vala doesn't support that yet.  It only supports static
    // detailed signals (changed['my-specific-key']).
    if (watched_keys == null)
      settings.changed.connect(settings_changed);
    
    watched_keys.prepend(key);
  }
  
  void settings_changed(string key)
  {
    foreach (string k in watched_keys) {
      if (k == key)
        key_changed();
    }
  }
  
  void key_changed()
  {
    set_from_config();
    changed();
  }

  protected abstract async void set_from_config();
}

}

