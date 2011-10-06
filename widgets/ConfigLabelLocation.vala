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
  SimpleSettings file_root;
  SimpleSettings s3_root;
  SimpleSettings u1_root;
  SimpleSettings rackspace_root;

  public ConfigLabelLocation()
  {
    base(null);
  }
  
  construct {
    label.wrap = true;
    label.max_width_chars = 30;
    img = new Gtk.Image.from_icon_name("folder", Gtk.IconSize.MENU);
    img.set("yalign", 0.0f);
    fill_box();
    watch_key(BACKEND_KEY);
    watch_key(null, (file_root = DejaDup.get_settings(FILE_ROOT)));
    watch_key(null, (s3_root = DejaDup.get_settings(S3_ROOT)));
    watch_key(null, (u1_root = DejaDup.get_settings(U1_ROOT)));
    watch_key(null, (rackspace_root = DejaDup.get_settings(RACKSPACE_ROOT)));
    set_from_config();
  }

  protected override void fill_box()
  {
    if (img == null)
      return;

    hbox.pack_start(img, false, false, 0);
    hbox.pack_start(label, true, true, 0);
  }

  protected override async void set_from_config()
  {
    if (img == null)
      return;

    var backend = Backend.get_default();

    string desc = null;
    try {
      desc = backend.get_location_pretty();
    }
    catch (Error e) {}
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

