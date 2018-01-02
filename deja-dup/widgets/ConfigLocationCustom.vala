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

public class ConfigLocationCustom : ConfigLocationTable
{
  public ConfigLocationCustom(Gtk.SizeGroup sg, FilteredSettings settings) {
    Object(label_sizes: sg, settings: settings);
  }

  Gtk.Popover hint = null;
  construct {
    var address = new ConfigEntry(DejaDup.REMOTE_URI_KEY, DejaDup.REMOTE_ROOT,
                                  settings, true);
    address.set_accessible_name("CustomAddress");
    address.entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY,
                                          "dialog-question-symbolic");
    address.entry.icon_press.connect(show_hint);
    add_widget(_("_Network Location"), address);

    hint = create_hint(address.entry);

    var folder = new ConfigFolder(DejaDup.REMOTE_FOLDER_KEY, DejaDup.REMOTE_ROOT, settings, true);
    folder.set_accessible_name("CustomFolder");
    add_widget(_("_Folder"), folder);
  }

  void show_hint(Gtk.Entry entry, Gtk.EntryIconPosition icon_pos, Gdk.Event event)
  {
    Gdk.Rectangle rect = entry.get_icon_area(icon_pos);
    hint.set_pointing_to(rect);
    hint.show_all();
  }

  Gtk.Popover create_hint(Gtk.Entry parent)
  {
    var builder = new Gtk.Builder.from_resource("/org/gnome/DejaDup/server-hint.ui");
    var popover = builder.get_object("server_adresses_popover") as Gtk.Popover;
    popover.relative_to = parent;
    return popover;
  }
}

}

