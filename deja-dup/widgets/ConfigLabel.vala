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

public class ConfigLabel : ConfigWidget
{
  public ConfigLabel(string? key, string ns="")
  {
    Object(key: key, ns: ns);
  }
  
  protected Gtk.Grid box;
  protected Gtk.Label label;
  construct {
    label = new Gtk.Label("");
    box = new Gtk.Grid();
    box.column_spacing = 6;
    add(box);
    fill_box();
    set_from_config.begin();
  }

  protected virtual void fill_box()
  {
    label.xalign = 0.0f;
    label.hexpand = true;
    box.add(label);
  }

  protected override async void set_from_config()
  {
    label.label = settings.get_string(key);
  }
}

}

