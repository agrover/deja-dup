/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008 Michael Terry <mike@mterry.name>

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

public class ConfigFolder : ConfigWidget
{
  public ConfigFolder(string key)
  {
    this.key = key;
  }
  
  Gtk.FileChooserButton button;
  construct {
    button = new Gtk.FileChooserButton(_("Select Folder"),
                                       Gtk.FileChooserAction.SELECT_FOLDER);
    add(button);
    
    set_from_config();
    button.file_set += handle_file_set;
  }
  
  protected override void set_from_config()
  {
    string val;
    try {
      val = client.get_string(key);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return;
    }
    if (val == null)
      val = ""; // There should really be a better default, but I'm not sure
                // what.  The first mounted volume we see?  Create a directory
                // in $HOME called 'deja-dup'?
    button.set_filename(val);
  }
  
  void handle_file_set()
  {
    try {
      client.set_string(key, button.get_filename());
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
}

