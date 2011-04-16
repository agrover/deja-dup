/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008,2009,2010,2011 Michael Terry <mike@mterry.name>

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

public class Preferences : Gtk.HBox
{
  Gtk.SizeGroup label_sizes;
  Gtk.SizeGroup button_sizes;

  construct {
    Gtk.Notebook notebook = new Gtk.Notebook();
    Gtk.Widget w;
    Gtk.VBox page_box;
    Gtk.Box hbox;
    Gtk.Label label;
    Gtk.Table table;
    int row;
    Gtk.TreeIter iter;
    int i = 0;

    spacing = 12;
    border_width = 12;

    var cat_model = new Gtk.ListStore(2, typeof(string), typeof(int));
    var tree = new Gtk.TreeView.with_model(cat_model);
    tree.headers_visible = false;
    tree.insert_column_with_attributes(-1, null, new Gtk.CellRendererText(),
                                       "text", 0);
    tree.get_selection().set_mode(Gtk.SelectionMode.SINGLE);
    tree.get_selection().changed.connect(() => {
      Gtk.TreeIter sel_iter;
      int page;
      if (tree.get_selection().get_selected(null, out sel_iter)) {
        cat_model.get(sel_iter, 1, out page);
        notebook.page = page;
      }
    });
    pack_start(tree, false, false);

    page_box = new Gtk.VBox(false, 0);
    page_box.border_width = 6;
    table = new Gtk.Table(0, 0, false);
    table.row_spacing = 6;
    table.column_spacing = 6;
    row = 0;
    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);

    w = new Gtk.Alignment(0.0f, 0.5f, 0.0f, 0.0f);
    (w as Gtk.Bin).add(new DejaDup.ConfigSwitch(DejaDup.PERIODIC_KEY));
    label = new Gtk.Label(_("Automatic _backups:"));
    label.set("mnemonic-widget", (w as Gtk.Bin).get_child(),
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);

    table.attach(label, 0, 1, row, row + 1,
                 Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    table.attach(w, 1, 2, row, row + 1, 
                 Gtk.AttachOptions.FILL,
                 Gtk.AttachOptions.FILL, 0, 0);
    ++row;

    w = new DejaDup.ConfigLabelLocation();
    label = new Gtk.Label(_("Where:"));
    label.set("xalign", 0.0f);
    label_sizes.add_widget(label);

    table.attach(label, 0, 1, row, row + 1,
                 Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    table.attach(w, 1, 2, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 0, 0);
    ++row;

    hbox = new Gtk.HButtonBox();
    hbox.border_width = 3;
    hbox.spacing = 12;
    (hbox as Gtk.HButtonBox).layout_style = Gtk.ButtonBoxStyle.END;
    w = new Gtk.Button.with_mnemonic(_("_Restore…"));
    (w as Gtk.Button).clicked.connect(() => {
      try {
        Process.spawn_command_line_async("deja-dup --restore");
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    });
    hbox.add(w);
    w = new Gtk.Button.with_mnemonic(_("Back Up _Now"));
    (w as Gtk.Button).clicked.connect(() => {
      try {
        Process.spawn_command_line_async("deja-dup --backup");
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    });
    hbox.add(w);
    w = new Gtk.Button.from_stock(Gtk.Stock.HELP);
    (w as Gtk.Button).clicked.connect(() => {
      DejaDup.show_uri(this.get_toplevel() as Gtk.Window, "ghelp:deja-dup");
    });
    hbox.add(w);
    (hbox as Gtk.HButtonBox).set_child_secondary(w, true);

    page_box.pack_start(table, true, true, 0);
    page_box.pack_end(hbox, false, false, 0);
    notebook.append_page(page_box, null);
    cat_model.insert_with_values(out iter, i, 0, _("Overview"), 1, i);
    ++i;

    // Reset page
    page_box = new Gtk.VBox(false, 0);
    page_box.border_width = 6;
    table = new Gtk.Table(0, 0, false);
    table.row_spacing = 6;
    table.column_spacing = 6;
    row = 0;
    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    button_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);

    var location = new DejaDup.ConfigLocation(label_sizes);
    label = new Gtk.Label(_("_Backup location:"));
    label.set("mnemonic-widget", location,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);

    table.attach(label, 0, 1, row, row + 1,
                 Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    table.attach(location, 1, 2, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 0, 0);
    ++row;

    table.attach(location.extras, 0, 2, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 0, 0);
    ++row;

    w = new DejaDup.ConfigBool(DejaDup.ENCRYPT_KEY, _("_Encrypt backup files"));
    table.attach(w, 0, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 0, 0);
    ++row;
    
    w = new DejaDup.ConfigLabelPolicy();
    hbox = new Gtk.HBox(false, 0);
    hbox.border_width = 3;
    hbox.add(w);
    
    page_box.pack_start(table, true, true, 0);
    page_box.pack_end(hbox, false, false, 0);
    notebook.append_page(page_box, null);
    cat_model.insert_with_values(out iter, i, 0, _("Storage"), 1, i);
    ++i;

    // Now make sure to reserve the excess space that the hidden bits of
    // ConfigLocation will need.
    Gtk.Requisition req, hidden;
    page_box.show_all();
    page_box.get_preferred_size(null, out req);
    hidden = location.hidden_size();
    req.width = req.width + hidden.width;
    req.height = req.height + hidden.height;
    page_box.set_size_request(req.width, req.height);

    // Reset page
    page_box = new Gtk.VBox(false, 0);
    page_box.set("border-width", 3);
    table = new Gtk.Table(0, 3, false);
    row = 0;
    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    button_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    
    w = new DejaDup.ConfigList(DejaDup.INCLUDE_LIST_KEY, button_sizes);
    w.set_size_request(300, 80);
    label = new Gtk.Label(_("I_nclude files in folders:"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "wrap", true,
              "width-request", 150,
              "xalign", 0.0f,
              "yalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, 1, row, row + 1,
                 Gtk.AttachOptions.FILL,
                 Gtk.AttachOptions.FILL, 3, 3);
    table.attach(w, 1, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 3, 3);
    ++row;
    
    w = new DejaDup.ConfigList(DejaDup.EXCLUDE_LIST_KEY, button_sizes);
    w.set_size_request(300, 120);
    label = new Gtk.Label(_("E_xcept files in folders:"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "wrap", true,
              "width-request", 150,
              "xalign", 0.0f,
              "yalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, 1, row, row + 1,
                 Gtk.AttachOptions.FILL,
                 Gtk.AttachOptions.FILL, 3, 3);
    table.attach(w, 1, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 3, 3);
    ++row;
    
    page_box.pack_start(table, true, true, 0);
    notebook.append_page(page_box, null);
    cat_model.insert_with_values(out iter, i, 0, _("Files"), 1, i);
    ++i;
    
    // Reset page
    page_box = new Gtk.VBox(false, 0);
    page_box.set("border-width", 3);
    table = new Gtk.Table(0, 3, false);
    row = 0;
    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    button_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    
    w = new DejaDup.ConfigPeriod(DejaDup.PERIODIC_PERIOD_KEY);
    label = new Gtk.Label(_("How _often to back up:"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, 1, row, row + 1,
                 Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 3, 3);
    table.attach(w, 1, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL,
                 3, 3);
    ++row;
    
    w = new DejaDup.ConfigDelete(DejaDup.DELETE_AFTER_KEY);
    label = new Gtk.Label("%s".printf(_("_Keep backups:")));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, 1, row, row + 1,
                 Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 3, 3);
    table.attach(w, 1, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL,
                 3, 3);
    ++row;
    
    w = new DejaDup.ConfigLabelPolicy();
    hbox = new Gtk.HBox(false, 0);
    hbox.border_width = 3;
    hbox.add(w);
    
    page_box.pack_start(table, true, true, 0);
    page_box.pack_end(hbox, false, false, 0);
    notebook.append_page(page_box, null);
    cat_model.insert_with_values(out iter, i, 0, _("Schedule"), 1, i);
    ++i;

    // Select first one by deault
    cat_model.get_iter_first(out iter);
    tree.get_selection().select_iter(iter);

    notebook.show_tabs = false;
    notebook.show_border = false;
    pack_start(notebook, true, true);
  }
}

}
