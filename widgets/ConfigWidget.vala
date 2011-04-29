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

  public Gtk.Widget mnemonic_widget {get; protected set;}
  public string key {get; construct;}
  public string ns {get; construct; default = "";}
  
  protected SimpleSettings settings;
  construct {
    settings = DejaDup.get_settings(ns);
    
    if (key != null)
      watch_key(key);

    mnemonic_activate.connect(on_mnemonic_activate);
  }
  
  // If you pass in a special settings object, make sure it survives the
  // lifetime of this widget.
  protected void watch_key(string? key, SimpleSettings? s = null)
  {
    if (s == null)
      s = settings;
    var signal_name = (key == null) ? "change-event" : "changed::%s".printf(key);
    Signal.connect_swapped(s, signal_name, (Callback)key_changed_wrapper, this);
  }

  static bool key_changed_wrapper(ConfigWidget w)
  {
    w.key_changed();
    return false;
  }

  void key_changed()
  {
    set_from_config();
    changed();
  }

  protected abstract async void set_from_config();

  bool on_mnemonic_activate(Gtk.Widget w, bool g)
  {
    if (mnemonic_widget != null)
      return mnemonic_widget.mnemonic_activate(g);
    else
      return false;
  }
}

}

