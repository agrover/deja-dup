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

public class ConfigLocationTable : Gtk.Grid
{
  public Gtk.SizeGroup label_sizes {get; construct;}

  protected int row = 0;
  public ConfigLocationTable(Gtk.SizeGroup sg) {
    Object(label_sizes: sg);
  }

  construct {
    row_spacing = 6;
    column_spacing = 12;
  }

  protected void add_widget(string msg, Gtk.Widget w,
                            Togglable? check = null,
                            Gtk.Widget? mnemonic = null)
  {
    var label = new Gtk.Label(msg);
    label.set("mnemonic-widget", (mnemonic != null) ? mnemonic : w,
              "use-underline", true,
              "xalign", 1.0f);
    label_sizes.add_widget(label);
    add_widget_with_label(label, w, check);
  }

  protected void add_widget_with_label(Gtk.Widget label, Gtk.Widget w,
                                       Togglable? check = null)
  {
    this.attach(label, 0, row, 1, 1);

    w.set("hexpand", true);
    this.attach(w, 1, row, 1, 1);
    ++row;

    if (check != null) {
      if ((label as Object) != (check as Object))
        label.sensitive = check.get_active();
      w.sensitive = check.get_active();
      check.toggled.connect(() => {
        if ((label as Object) != (check as Object))
          label.sensitive = check.get_active();
        w.sensitive = check.get_active();
      });
    }
  }

  protected void add_wide_widget(Gtk.Widget w, Togglable? check = null)
  {
    w.hexpand = true;
    this.attach(w, 0, row, 2, 1);
    ++row;

    if (check != null) {
      w.sensitive = check.get_active();
      check.toggled.connect(() => {
        w.sensitive = check.get_active();
      });
    }
  }
}

}

