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

public class ConfigLocationSSH : ConfigLocationTable
{
  public ConfigLocationSSH(Gtk.SizeGroup sg) {
    Object(label_sizes: sg);
  }

  construct {
    add_widget(_("_Server"), new ConfigURLPart(ConfigURLPart.Part.SERVER,
                                               DejaDup.FILE_PATH_KEY,
                                               DejaDup.FILE_ROOT));
    add_widget(_("_Port"), new ConfigURLPart(ConfigURLPart.Part.PORT,
                                             DejaDup.FILE_PATH_KEY,
                                             DejaDup.FILE_ROOT));
    add_widget(_("_Folder"), new ConfigURLPart(ConfigURLPart.Part.FOLDER,
                                               DejaDup.FILE_PATH_KEY,
                                               DejaDup.FILE_ROOT));
    add_widget(_("_Username"), new ConfigURLPart(ConfigURLPart.Part.USER,
                                                 DejaDup.FILE_PATH_KEY,
                                                 DejaDup.FILE_ROOT));
  }
}

}

