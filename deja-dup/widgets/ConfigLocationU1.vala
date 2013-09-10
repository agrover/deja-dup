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

public class ConfigLocationU1 : ConfigLocationTable
{
  public ConfigLocationU1(Gtk.SizeGroup sg) {
    Object(label_sizes: sg);
  }

  construct {
    var entry = new ConfigFolder(DejaDup.U1_FOLDER_KEY, DejaDup.U1_ROOT);
    entry.set_accessible_name("U1Folder");
    add_widget(_("_Folder"), entry);
  }
}

}

