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

public class ConfigLabelLocation : ConfigLabel
{
  Gtk.Image img;
  public ConfigLocation location {get; construct;}

  public ConfigLabelLocation(ConfigLocation location)
  {
    Object(key: null, location: location);
  }
  
  construct {
    img = new Gtk.Image.from_icon_name("folder", Gtk.IconSize.MENU);
    fill_box();
    foreach (var setting in location.get_all_settings()) {
      watch_key(null, setting);
    }
    set_from_config.begin();
  }

  protected override void fill_box()
  {
    if (img == null)
      return;

    img.expand = false;
    box.add(img);

    label.xalign = 0.0f;
    label.ellipsize = Pango.EllipsizeMode.MIDDLE;
    box.add(label);
  }

  protected override async void set_from_config()
  {
    if (img == null)
      return;

    var backend = location.get_backend();

    string desc = backend.get_location_pretty();
    if (desc == null)
      desc = "";
    label.label = desc;

    Icon icon = backend.get_icon();
    if (icon == null)
      img.set_from_icon_name("folder", Gtk.IconSize.MENU);
    else
      img.set_from_gicon(icon, Gtk.IconSize.MENU);
  }
}

}

