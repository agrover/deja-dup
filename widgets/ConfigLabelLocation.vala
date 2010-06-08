/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2009–2010 Michael Terry <mike@mterry.name>

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
  public bool is_s3 {get; private set;}
  Gtk.Image img;

  public ConfigLabelLocation()
  {
    base(null);
  }
  
  construct {
    img = new Gtk.Image.from_icon_name("folder", Gtk.IconSize.MENU);
    hbox.pack_start(img, false, false, 0);
    hbox.reorder_child(img, 0);
    watch_key(BACKEND_KEY);
    watch_key(FILE_ROOT_KEY);
    watch_key(S3_ROOT_KEY);
    set_from_config();
  }
  
  protected override async void set_from_config()
  {
    label.label = get_location_desc();

    if (img != null) {
      Icon icon = null;
      try {
        icon = Backend.get_default().get_icon();
      }
      catch (Error e) {}
      if (icon == null)
        img.set_from_icon_name("folder", Gtk.IconSize.MENU);
      else
        img.set_from_gicon(icon, Gtk.IconSize.MENU);
    }

    is_s3 = settings.get_value(BACKEND_KEY).get_string() == "s3";
  }
}

}

