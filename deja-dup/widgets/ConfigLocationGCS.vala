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

public class ConfigLocationGCS : ConfigLocationTable
{
  public ConfigLocationGCS(Gtk.SizeGroup sg, FilteredSettings settings) {
    Object(label_sizes: sg, settings: settings);
  }

  construct {
    // Translators: GCS is Google Cloud Services
    add_widget(_("GCS Access Key I_D"),
               new ConfigEntry(DejaDup.GCS_ID_KEY, DejaDup.GCS_ROOT, settings));
    // Translators: "Bucket" refers to a term used by Google Cloud Services
    // see https://cloud.google.com/storage/docs/key-terms#bucket
    add_widget(_("_Bucket"),
               new ConfigEntry(DejaDup.GCS_BUCKET_KEY, DejaDup.GCS_ROOT, settings));
    add_widget(_("_Folder"),
               new ConfigFolder(DejaDup.GCS_FOLDER_KEY, DejaDup.GCS_ROOT, settings));
  }
}

}

