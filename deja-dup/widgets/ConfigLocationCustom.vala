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
  public ConfigLocationCustom(Gtk.SizeGroup sg) {
    Object(label_sizes: sg);
  }

  construct {
    var entry = new ConfigEntry(DejaDup.FILE_PATH_KEY, DejaDup.FILE_ROOT,
                                true);
    entry.set_accessible_name("CustomFolder");
    add_widget(_("Server _Address"), entry);

    int row = 0;

    var hint = new Gtk.Grid();
    hint.row_spacing = 6;

    add_label(hint, 0, row++, 2, 1, _("Server addresses are made up of a protocol prefix and an address. Examples:"));

    add_label(hint, 0, row++, 2, 1, "smb://gnome.org, ssh://192.168.0.1, ftp://[2001:db8::1]");

    add_label(hint, 0, row, 1, 1, "<b>%s</b>".printf(_("Available Protocols")), 6);
    add_label(hint, 1, row++, 1, 1, "<b>%s</b>".printf(_("Prefix")), 6);

    add_label(hint, 0, row, 1, 1, _("AppleTalk"));
    add_label(hint, 1, row++, 1, 1, "afp://");

    add_label(hint, 0, row, 1, 1, _("File Transfer Protocol"));
    // Translators: do not translate ftp:// and ftps://
    add_label(hint, 1, row++, 1, 1, _("ftp:// or ftps://"));

    add_label(hint, 0, row, 1, 1, _("Network File System"));
    add_label(hint, 1, row++, 1, 1, "nfs://");

    add_label(hint, 0, row, 1, 1, _("Samba"));
    add_label(hint, 1, row++, 1, 1, "smb://");

    add_label(hint, 0, row, 1, 1, _("SSH File Transfer Protocol"));
    // Translators: do not translate sftp:// and ssh://
    add_label(hint, 1, row++, 1, 1, _("sftp:// or ssh://"));

    add_label(hint, 0, row, 1, 1, _("WebDav"));
    // Translators: do not translate dav:// and davs://
    add_label(hint, 1, row++, 1, 1, _("dav:// or davs://"));

    hint.show_all();
    add_widget("", hint);
  }

  void add_label(Gtk.Grid grid, int left, int top, int width, int height, string text, int margin_top = 0)
  {
    var label = new Gtk.Label(text);
    label.wrap = true;
    label.max_width_chars = 50;
    label.use_markup = true;
    label.xalign = 0.0f;
    label.margin_top = margin_top;
    grid.attach(label, left, top, width, height);
  }
}

}

