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

public class Preferences : Gtk.Box
{
  Gtk.Notebook top_notebook;
  Gtk.Widget backup_button;
  Gtk.Widget restore_button;
  uint bus_watch_id = 0;

  ~Preferences() {
    if (bus_watch_id > 0) {
      Bus.unwatch_name(bus_watch_id);
      bus_watch_id = 0;
    }
  }

  Gtk.Widget make_welcome_page()
  {
    var restore_button = new Gtk.Button();
    restore_button.clicked.connect((b) => {
      run_deja_dup("--restore", b.get_display().get_app_launch_context());
    });
    var restore_label = new Gtk.Label("<big>%s</big>".printf(_("I want to _restore files from a previous backup…")));
    restore_label.set("mnemonic-widget", restore_button,
                      "wrap", true,
                      "justify", Gtk.Justification.CENTER,
                      "xpad", 6,
                      "ypad", 6,
                      "width-request", 300,
                      "use-markup", true,
                      "use-underline", true);
    restore_button.add(restore_label);

    var continue_button = new Gtk.Button();
    continue_button.clicked.connect(() => {
      var settings = DejaDup.get_settings();
      settings.set_boolean(DejaDup.WELCOMED_KEY, true);
      top_notebook.page = 1;
    });
    var continue_label = new Gtk.Label("<big>%s</big>".printf(_("Just show my backup _settings")));
    continue_label.set("mnemonic-widget", continue_button,
                       "wrap", true,
                       "justify", Gtk.Justification.CENTER,
                       "xpad", 6,
                       "ypad", 6,
                       "width-request", 300,
                       "use-markup", true,
                       "use-underline", true);
    continue_button.add(continue_label);

    var bbox = new Gtk.ButtonBox(Gtk.Orientation.VERTICAL);
    bbox.spacing = 24;
    bbox.layout_style = Gtk.ButtonBoxStyle.CENTER;
    bbox.add(restore_button);
    bbox.add(continue_button);

    var balign = new Gtk.Alignment(0.5f, 0.5f, 0.0f, 0.0f);
    balign.add(bbox);

    var icon = new Gtk.Image();
    icon.set("icon-name", "deja-dup",
             "pixel-size", 256);

    var label = new Gtk.Label("<b><big>%s</big></b>".printf(_("Déjà Dup Backup Tool")));
    label.set("wrap", true,
              "justify", Gtk.Justification.CENTER,
              "use-markup", true);

    var ibox = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    ibox.pack_start(icon, false, false);
    ibox.pack_start(label, false, false);

    var ialign = new Gtk.Alignment(0.5f, 0.5f, 0.0f, 0.0f);
    ialign.add(ibox);

    var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
    hbox.set("homogeneous", true);
    hbox.pack_start(ialign, true, false);
    hbox.pack_start(balign, true, false);

    var page = new Gtk.Alignment(0.0f, 0.5f, 1.0f, 0.0f);
    page.add(hbox);

    continue_button.set("has-focus", true);

    page.show();
    return page;
  }

  Gtk.Widget make_settings_page() {
    var settings_page = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
    Gtk.Notebook notebook = new Gtk.Notebook();
    Gtk.Widget w;
    Gtk.Box page_box;
    Gtk.Box hbox;
    Gtk.Label label;
    Gtk.Grid table;
    int row;
    Gtk.TreeIter iter;
    int i = 0;
    Gtk.SizeGroup label_sizes;
    Gtk.SizeGroup button_sizes;

    settings_page.spacing = 12;

    var cat_model = new Gtk.ListStore(2, typeof(string), typeof(int));
    var tree = new Gtk.TreeView.with_model(cat_model);
    var accessible = tree.get_accessible();
    if (accessible != null) {
      accessible.set_name("Categories");
      accessible.set_description(_("Categories"));
    }
    tree.headers_visible = false;
    tree.set_size_request(150, -1);
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
    settings_page.pack_start(tree, false, false);

    table = new Gtk.Grid();
    table.orientation = Gtk.Orientation.VERTICAL;
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

    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    w = new Gtk.EventBox(); // spacer
    w.height_request = 12; // plus 6 pixels on either side
    table.attach(w, 0, row, 2, 1);
    ++row;

    w = new DejaDup.ConfigLabelLocation();
    w.set("hexpand", true);
    label = new Gtk.Label(_("Where:"));
    label.set("xalign", 0.0f,
              "yalign", 0.0f);
    label_sizes.add_widget(label);

    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    label = new Gtk.Label(_("Include files from:"));
    label.set("xalign", 0.0f, "yalign", 0.0f);
    label_sizes.add_widget(label);
    w = new DejaDup.ConfigLabelList(DejaDup.INCLUDE_LIST_KEY);
    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    label = new Gtk.Label(_("Except for:"));
    label.set("xalign", 0.0f, "yalign", 0.0f);
    label_sizes.add_widget(label);
    w = new DejaDup.ConfigLabelList(DejaDup.EXCLUDE_LIST_KEY);
    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    w = new Gtk.EventBox(); // spacer
    w.height_request = 12; // plus 6 pixels on either side
    table.attach(w, 0, row, 2, 1);
    ++row;

    var bdate_label = new Gtk.Label(_("Most recent backup:"));
    bdate_label.xalign = 0.0f;
    label_sizes.add_widget(bdate_label);
    var bdate = new DejaDup.ConfigLabelBackupDate(DejaDup.ConfigLabelBackupDate.Kind.LAST);

    bdate_label.show_all();
    bdate.show_all();
    bdate_label.no_show_all = true;
    bdate.no_show_all = true;
    bdate_label.visible = !bdate.empty;
    bdate.visible = !bdate.empty;
    bdate.notify["empty"].connect(() => {
      bdate_label.visible = !bdate.empty;
      bdate.visible = !bdate.empty;
    });

    table.attach(bdate_label, 0, row, 1, 1);
    table.attach(bdate, 1, row, 1, 1);
    ++row;

    var ndate_label = new Gtk.Label(_("Next automatic backup:"));
    ndate_label.xalign = 0.0f;
    label_sizes.add_widget(ndate_label);
    var ndate = new DejaDup.ConfigLabelBackupDate(DejaDup.ConfigLabelBackupDate.Kind.NEXT);

    ndate_label.show_all();
    ndate.show_all();
    ndate_label.no_show_all = true;
    ndate.no_show_all = true;
    ndate_label.visible = !ndate.empty;
    ndate.visible = !ndate.empty;
    ndate.notify["empty"].connect(() => {
      ndate_label.visible = !ndate.empty;
      ndate.visible = !ndate.empty;
    });

    table.attach(ndate_label, 0, row, 1, 1);
    table.attach(ndate, 1, row, 1, 1);
    ++row;

    w = new Gtk.EventBox(); // spacer
    w.height_request = 12; // plus 6 pixels on either side
    table.attach(w, 0, row, 2, 1);
    ++row;

    w = new DejaDup.ConfigLabelPolicy();
    w.expand = true;
    w.valign = Gtk.Align.END;
    table.attach(w, 0, row, 2, 1);
    ++row;

    w = new Gtk.EventBox(); // spacer
    w.height_request = 12; // plus 6 pixels on either side
    table.attach(w, 0, row, 2, 1);
    ++row;

    hbox = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
    hbox.spacing = 12;

    (hbox as Gtk.ButtonBox).layout_style = Gtk.ButtonBoxStyle.END;
    w = new Gtk.Button.with_mnemonic(_("_Restore…"));
    (w as Gtk.Button).clicked.connect((b) => {
      run_deja_dup("--restore", b.get_display().get_app_launch_context());
    });
    restore_button = w;
    hbox.add(w);
    w = new Gtk.Button.with_mnemonic(_("Back Up _Now"));
    (w as Gtk.Button).clicked.connect((b) => {
      run_deja_dup("--backup", b.get_display().get_app_launch_context());
    });
    backup_button = w;
    hbox.add(w);
    w = new Gtk.Button.from_stock(Gtk.Stock.HELP);
    (w as Gtk.Button).clicked.connect(() => {
      DejaDup.show_uri(this.get_toplevel() as Gtk.Window, "ghelp:deja-dup");
    });
    hbox.add(w);
    (hbox as Gtk.ButtonBox).set_child_secondary(w, true);

    bus_watch_id = Bus.watch_name(BusType.SESSION, "org.gnome.DejaDup.Operation",
                                  BusNameWatcherFlags.NONE,
                                  () => {restore_button.sensitive = false;
                                         backup_button.sensitive = false;},
                                  () => {restore_button.sensitive = true;
                                         backup_button.sensitive = true;});

    table.attach(hbox, 0, row, 2, 1);
    notebook.append_page(table, null);
    cat_model.insert_with_values(out iter, i, 0, _("Overview"), 1, i);
    ++i;

    // Reset page
    page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    table = new Gtk.Grid();
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

    table.attach(label, 0, row, 1, 1);
    table.attach(location, 1, row, 1, 1);
    location.set("hexpand", true);
    ++row;

    location.extras.set("hexpand", true);
    table.attach(location.extras, 0, row, 2, 1);
    ++row;
    
    w = new DejaDup.ConfigDelete(DejaDup.DELETE_AFTER_KEY);
    label = new Gtk.Label("%s".printf(_("_Keep backups:")));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    w = new DejaDup.ConfigLabelPolicy();
    w.set("expand", true);
    table.attach(w, 0, row, 2, 1);
    ++row;
    
    page_box.pack_start(table, true, true, 0);
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
    page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    table = new Gtk.Grid();
    table.row_spacing = 6;
    table.column_spacing = 6;
    row = 0;
    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    button_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    
    w = new DejaDup.ConfigList(DejaDup.INCLUDE_LIST_KEY, button_sizes);
    w.set_size_request(300, 80);
    w.set("expand", true);
    label = new Gtk.Label(_("I_nclude files in folders:"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "wrap", true,
              "max-width-chars", 10,
              "xalign", 0.0f,
              "yalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;
    
    w = new DejaDup.ConfigList(DejaDup.EXCLUDE_LIST_KEY, button_sizes);
    w.set_size_request(300, 120);
    w.set("expand", true);
    label = new Gtk.Label(_("E_xcept files in folders:"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "wrap", true,
              "max-width-chars", 10,
              "xalign", 0.0f,
              "yalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;
    
    page_box.pack_start(table, true, true, 0);
    notebook.append_page(page_box, null);
    cat_model.insert_with_values(out iter, i, 0, _("Files"), 1, i);
    ++i;
    
    // Reset page
    page_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    table = new Gtk.Grid();
    table.row_spacing = 6;
    table.column_spacing = 6;
    row = 0;
    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    
    w = new DejaDup.ConfigPeriod(DejaDup.PERIODIC_PERIOD_KEY);
    label = new Gtk.Label(_("How _often to back up:"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    page_box.pack_start(table, true, true, 0);
    notebook.append_page(page_box, null);
    cat_model.insert_with_values(out iter, i, 0, _("Schedule"), 1, i);
    ++i;

    // Select first one by default
    cat_model.get_iter_first(out iter);
    tree.get_selection().select_iter(iter);

    notebook.show_tabs = false;
    notebook.show_border = false;
    settings_page.pack_start(notebook, true, true);

    settings_page.show();
    return settings_page;
  }

  bool should_show_welcome()
  {
    var settings = DejaDup.get_settings();

    var last_run = settings.get_string(DejaDup.LAST_RUN_KEY);
    var welcomed = settings.get_boolean(DejaDup.WELCOMED_KEY);

    return !welcomed && last_run == "";
  }

  construct {
    top_notebook = new Gtk.Notebook();
    top_notebook.append_page(make_welcome_page(), null);
    top_notebook.append_page(make_settings_page(), null);
    top_notebook.show_tabs = false;
    top_notebook.show_border = false;
    top_notebook.border_width = 12;
    top_notebook.page = should_show_welcome() ? 0 : 1;
    add(top_notebook);
  }
}

}
