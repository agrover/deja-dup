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

public abstract class ConfigWidget : Gtk.EventBox
{
  public signal void changed();

  public Gtk.Widget mnemonic_widget {get; protected set;}
  public string key {get; construct;}
  public string ns {get; construct; default = "";}

  protected bool syncing;  
  protected SimpleSettings settings;
  protected List<SimpleSettings> all_settings;
  construct {
    visible_window = false;

    settings = DejaDup.get_settings(ns);
    
    if (key != null)
      watch_key(key);

    mnemonic_activate.connect(on_mnemonic_activate);
  }

  ~ConfigWidget() {
    SignalHandler.disconnect_by_func(settings, (void*)key_changed_wrapper, this);
    foreach (weak SimpleSettings s in all_settings) {
      SignalHandler.disconnect_by_func(s, (void*)key_changed_wrapper, this);
      s.unref();
    }
  }

  protected void watch_key(string? key, SimpleSettings? s = null)
  {
    if (s == null) {
      s = settings;
    }
    else {
      s.ref();
      all_settings.prepend(s);
    }
    var signal_name = (key == null) ? "change-event" : "changed::%s".printf(key);
    Signal.connect_swapped(s, signal_name, (Callback)key_changed_wrapper, this);
  }

  static bool key_changed_wrapper(ConfigWidget w)
  {
    w.key_changed.begin();
    return false;
  }

  async void key_changed()
  {
    // Not great to just drop new notification on the floor when already 
    // syncing, but we don't have a good cancellation method.
    if (syncing)
      return;

    syncing = true;
    yield set_from_config();
    changed();
    syncing = false;
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

