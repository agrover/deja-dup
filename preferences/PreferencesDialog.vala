/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008–2010 Michael Terry <mike@mterry.name>

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

public class PreferencesDialog : Gtk.Dialog
{
  Gtk.SizeGroup label_sizes;
  Gtk.SizeGroup button_sizes;
  DejaDup.ToggleGroup periodic_toggle;

  public PreferencesDialog(Gtk.Window? parent = null) {
    transient_for = parent;
  }
  
  construct {
    set("title", _("Déjà Dup Preferences"),
        "has-separator", false);
    add_buttons(Gtk.Stock.CLOSE, Gtk.ResponseType.CLOSE,
                Gtk.Stock.HELP, Gtk.ResponseType.HELP);
    response.connect(handle_response);
    
    Gtk.Notebook notebook = new Gtk.Notebook();
    Gtk.Widget w;
    Gtk.VBox page_box;
    Gtk.HBox hbox;
    Gtk.Label label;
    Gtk.Table table;
    int row;
    
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
    notebook.set_tab_label_text(page_box, _("Storage"));

    // Now make sure to reserve the excess space that the hidden bits of
    // ConfigLocation will need.
    Gtk.Requisition req, hidden;
    page_box.show_all();
    page_box.size_request(out req);
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
    notebook.set_tab_label_text(page_box, _("Files"));
    
    // Reset page
    page_box = new Gtk.VBox(false, 0);
    page_box.set("border-width", 3);
    table = new Gtk.Table(0, 3, false);
    row = 0;
    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    button_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    
    DejaDup.ConfigBool periodic_check = new DejaDup.ConfigBool(DejaDup.PERIODIC_KEY, _("_Automatically back up on a regular schedule"));
    table.attach(periodic_check, 0, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 3, 3);
    ++row;
    
    w = new DejaDup.ConfigPeriod(DejaDup.PERIODIC_PERIOD_KEY);
    label = new Gtk.Label("    %s".printf(_("How _often to back up:")));
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
    periodic_toggle = new DejaDup.ToggleGroup(periodic_check);
    periodic_toggle.add_dependent(label);
    periodic_toggle.add_dependent(w);
    periodic_toggle.check();
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
    notebook.set_tab_label_text(page_box, _("Schedule"));

    var area = (Gtk.Box)get_content_area();
    area.add(notebook);
  }

  void handle_response(Gtk.Dialog dlg, int response) {
    switch (response) {
    case Gtk.ResponseType.HELP:
      DejaDup.show_uri(dlg, "ghelp:deja-dup#prefs");
      break;
    default:
      Gtk.main_quit();
      break;
    }
  }
}

