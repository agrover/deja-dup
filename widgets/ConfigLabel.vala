/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2009 Michael Terry <mike@mterry.name>

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

public class ConfigLabel : ConfigWidget
{
  public ConfigLabel(string? key)
  {
    Object(key: key);
  }
  
  protected Gtk.HBox hbox;
  protected Gtk.Label label;
  construct {
    label = new Gtk.Label("");
    label.set("xalign", 0.0f);
    hbox = new Gtk.HBox(false, 0);
    hbox.pack_start(label, true, true, 6);
    add(hbox);
    set_from_config();
  }
  
  protected override void set_from_config()
  {
    string val;
    try {
      val = client.get_string(key);
      label.label = val;
    }
    catch (Error e) {warning("%s\n", e.message);}
  }
}

}

