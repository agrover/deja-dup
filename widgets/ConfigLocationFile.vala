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

public class ConfigLocationFile : ConfigLocationTable
{
  public ConfigLocationFile(Gtk.SizeGroup sg) {
    Object(label_sizes: sg);
  }

  ConfigURLPart entry;
  construct {
    var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);

    entry = new ConfigURLPart(ConfigURLPart.Part.FOLDER,
                              DejaDup.FILE_PATH_KEY,
                              DejaDup.FILE_ROOT);
    entry.set_accessible_name("FileFolder");

    var browse = new Gtk.Button.with_mnemonic(_("_Choose Folder…"));
    browse.clicked.connect(browse_clicked);

    hbox.pack_start(entry, true, true, 0);
    hbox.pack_start(browse, false, false, 0);

    add_widget(_("_Folder"), hbox, null, entry);
  }

  void browse_clicked()
  {
    var dlg = new Gtk.FileChooserDialog(_("Choose Folder"),
                                        get_ancestor(typeof(Gtk.Window)) as Gtk.Window,
                                        Gtk.FileChooserAction.SELECT_FOLDER,
                                        Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                                        Gtk.Stock.OK, Gtk.ResponseType.ACCEPT);
    var dir = entry.get_text();
    dlg.set_current_folder(dir); // empty string will be current dir

    if (dlg.run() == Gtk.ResponseType.ACCEPT) {
      var settings = DejaDup.get_settings(DejaDup.FILE_ROOT);
      settings.set_string(DejaDup.FILE_PATH_KEY, dlg.get_uri());
    }

    destroy_widget(dlg);
  }
}

}

