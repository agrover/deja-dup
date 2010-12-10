/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2010 Michael Terry <mike@mterry.name>

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

public class ConfigLocationTable : Gtk.Table
{
  public Gtk.SizeGroup label_sizes {get; construct;}

  int row = 0;
  public ConfigLocationTable(Gtk.SizeGroup sg) {
    Object(label_sizes: sg);
  }

  protected void add_widget(string msg, Gtk.Widget w)
  {
    var label = new Gtk.Label("    %s".printf(msg));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    this.attach(label, 0, 1, row, row+1,
                0, Gtk.AttachOptions.FILL, 3, 3);
    this.attach(w, 1, 3, row, row+1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                Gtk.AttachOptions.FILL, 3, 3);
    ++row;
  }
}

}

