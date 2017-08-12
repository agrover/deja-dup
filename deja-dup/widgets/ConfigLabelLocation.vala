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
  FilteredSettings local_root;
  FilteredSettings remote_root;
  FilteredSettings drive_root;
  FilteredSettings goa_root;
  FilteredSettings s3_root;
  FilteredSettings rackspace_root;
  FilteredSettings openstack_root;
  FilteredSettings gcs_root;

  public ConfigLabelLocation()
  {
    base(null);
  }
  
  construct {
    img = new Gtk.Image.from_icon_name("folder", Gtk.IconSize.MENU);
    fill_box();
    watch_key(BACKEND_KEY);
    watch_key(null, (local_root = DejaDup.get_settings(LOCAL_ROOT)));
    watch_key(null, (remote_root = DejaDup.get_settings(REMOTE_ROOT)));
    watch_key(null, (drive_root = DejaDup.get_settings(DRIVE_ROOT)));
    watch_key(null, (goa_root = DejaDup.get_settings(GOA_ROOT)));
    watch_key(null, (s3_root = DejaDup.get_settings(S3_ROOT)));
    watch_key(null, (rackspace_root = DejaDup.get_settings(RACKSPACE_ROOT)));
    watch_key(null, (openstack_root = DejaDup.get_settings(OPENSTACK_ROOT)));
    watch_key(null, (gcs_root = DejaDup.get_settings(GCS_ROOT)));
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

    var backend = Backend.get_default();

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

