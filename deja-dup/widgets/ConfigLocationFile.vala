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
  public ConfigLocationFile(Gtk.SizeGroup sg, FilteredSettings settings) {
    Object(label_sizes: sg, settings: settings);
  }

  ConfigFolder entry;
  construct {
    var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);

    entry = new ConfigFolder(DejaDup.LOCAL_FOLDER_KEY,
                             DejaDup.LOCAL_ROOT, settings, true);
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
                                        _("_Cancel"), Gtk.ResponseType.CANCEL,
                                        _("_OK"), Gtk.ResponseType.ACCEPT);
    var home = File.new_for_path(Environment.get_home_dir());
    try {
      var dir = home.get_child_for_display_name(entry.get_text());
      dlg.set_current_folder_file(dir);
    } catch (Error e) {
      warning("%s", e.message);
    }

    if (dlg.run() == Gtk.ResponseType.ACCEPT) {
      var file = dlg.get_file();
      var path = home.get_relative_path(file);
      if (path == null)
        path = file.get_path();
      settings.set_string(DejaDup.LOCAL_FOLDER_KEY, path);
    }

    destroy_widget(dlg);
  }
}

}

