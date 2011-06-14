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

  protected int row = 0;
  public ConfigLocationTable(Gtk.SizeGroup sg) {
    Object(label_sizes: sg);
  }

  construct {
    row_spacing = 6;
    column_spacing = 6;
  }

  protected void add_widget(string msg, Gtk.Widget w,
                            Togglable? check = null,
                            Gtk.Widget? mnemonic = null)
  {
    string indent;
    if (check == null)
      indent = "    ";
    else
      indent = "        ";

    var label = new Gtk.Label("%s%s".printf(indent, msg));
    label.set("mnemonic-widget", (mnemonic != null) ? mnemonic : w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    this.attach(label, 0, 1, row, row+1,
                Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    this.attach(w, 1, 2, row, row+1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                Gtk.AttachOptions.FILL, 0, 0);
    ++row;

    if (check != null) {
      label.sensitive = check.get_active();
      w.sensitive = check.get_active();
      check.toggled.connect(() => {
        label.sensitive = check.get_active();
        w.sensitive = check.get_active();
      });
    }
  }

  protected void add_wide_widget(Gtk.Widget w, Togglable? check = null)
  {
    string indent;
    if (check == null)
      indent = "    ";
    else
      indent = "        ";

    var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
    var label = new Gtk.Label(indent);

    hbox.pack_start(label, false, false, 0);
    hbox.pack_start(w, true, true, 0);

    this.attach(hbox, 0, 2, row, row+1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                Gtk.AttachOptions.FILL, 0, 0);
    ++row;

    if (check != null) {
      hbox.sensitive = check.get_active();
      check.toggled.connect(() => {
        hbox.sensitive = check.get_active();
      });
    }
  }

  protected void add_optional_label()
  {
    var label = new Gtk.Label(_("Optional information:"));
    label.set("xalign", 0.0f);
    add_wide_widget(label);
  }
}

}

