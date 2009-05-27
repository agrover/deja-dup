/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008,2009 Michael Terry <mike@mterry.name>

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

public abstract class ConfigWidget : Gtk.EventBox
{
  public string key {get; construct;}
  
  List<string> dirs = null;
  protected GConf.Client client;
  construct {
    client = DejaDup.get_gconf_client();
    
    if (key != null)
      watch_key(key);
  }
  
  ~ConfigWidget()
  {
    foreach (string dir in dirs) {
      try {
        client.remove_dir(dir);
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    }
  }
  
  protected void watch_key(string key)
  {
    string dir = key;
    weak string end = dir.rchr(-1, '/');
    if (end != null)
      dir = dir.substring(0, dir.length - end.length);
    try {
      client.add_dir(dir, GConf.ClientPreloadType.NONE);
      client.notify_add(key, set_from_config);
      dirs.prepend(dir);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  protected abstract void set_from_config();
}

}

