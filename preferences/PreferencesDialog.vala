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
  static const int S3_LIST = 0;
  static const int NUM_LISTS = 1;
  List<Gtk.Widget>[] backend_widgets;
  
  Gtk.SizeGroup label_sizes;
  Gtk.SizeGroup button_sizes;
  DejaDup.ToggleGroup periodic_toggle;

  Gtk.HBox location_hbox;
  DejaDup.ConfigLabelLocation location_label_noedit;
  Gtk.Button location_label_button;
  
  public PreferencesDialog(Gtk.Window? parent = null) {
    transient_for = parent;
  }
  
  construct {
    set("title", _("Déjà Dup Preferences"));
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
    page_box.set("border-width", 3);
    table = new Gtk.Table(0, 3, false);
    row = 0;
    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    button_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);

    backend_widgets = new List<Gtk.Widget>[NUM_LISTS];
    
    // We can't start by showing a ConfigLocation, because many locations
    // will not be immediately available (remote URIs that aren't yet mounted,
    // removable drives that aren't connected).  No need to immediately prompt
    // for them, just so we can show.  Instead, start with a label, and allow
    // user to change to edit widget.  Of course, if the user has never backed
    // anything up, they want to start in edit mode.
    string last_run = null;
    try {
      var settings = DejaDup.get_settings();
      last_run = settings.get_string(DejaDup.LAST_RUN_KEY);
    }
    catch (Error e) {warning("%s\n", e.message);}

    location_hbox = new Gtk.HBox(false, 6);
    location_hbox.set("border-width", 0);

    if (last_run != null && last_run != "") {
      location_label_noedit = new DejaDup.ConfigLabelLocation();
      location_label_noedit.changed.connect(handle_location_label_changed);
      location_label_button = new Gtk.Button.from_stock(Gtk.Stock.EDIT);
      location_label_button.clicked.connect(handle_edit_location);
      button_sizes.add_widget(location_label_button);
      location_hbox.pack_start(location_label_noedit, true, true, 0);
      location_hbox.pack_start(location_label_button, false, false, 0);
    }

    label = new Gtk.Label(_("_Backup location:"));
    label.set("mnemonic-widget", location_hbox,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);

    table.attach(label, 0, 1, row, row + 1,
                 0, Gtk.AttachOptions.FILL, 3, 3);
    table.attach(location_hbox, 1, 2, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 3, 3);
    ++row;
    
    var s3_table = new Gtk.Table(1, 3, false);
    w = new DejaDup.ConfigEntry(DejaDup.S3_ID_KEY, DejaDup.S3_ROOT);
    label = new Gtk.Label("    %s".printf(_("S3 Access Key I_D:")));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    s3_table.attach(label, 0, 1, 0, 1,
                    0, Gtk.AttachOptions.FILL, 3, 3);
    s3_table.attach(w, 1, 3, 0, 1,
                    Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                    Gtk.AttachOptions.FILL, 3, 3);
    
    w = new DejaDup.ConfigEntry(DejaDup.S3_FOLDER_KEY, DejaDup.S3_ROOT);
    label = new Gtk.Label("    %s".printf(_("_Folder:")));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    s3_table.attach(label, 0, 1, 1, 2,
                    0, Gtk.AttachOptions.FILL, 3, 3);
    s3_table.attach(w, 1, 3, 1, 2,
                    Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                    Gtk.AttachOptions.FILL, 3, 3);
    
    table.attach(s3_table, 0, 3, row, row + 1,
                 Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL,
                 0, 0);
    backend_widgets[S3_LIST].append(s3_table);
    ++row;
    
    w = new DejaDup.ConfigBool(DejaDup.ENCRYPT_KEY, _("_Encrypt backup files"));
    table.attach(w, 0, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 3, 3);
    ++row;
    
    w = new DejaDup.ConfigLabelPolicy();
    hbox = new Gtk.HBox(false, 0);
    hbox.border_width = 3;
    hbox.add(w);
    
    page_box.pack_start(table, true, true, 0);
    page_box.pack_end(hbox, false, false, 0);
    notebook.append_page(page_box, null);
    notebook.set_tab_label_text(page_box, _("Storage"));
    
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
                 0, Gtk.AttachOptions.FILL, 3, 3);
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
                 0, Gtk.AttachOptions.FILL, 3, 3);
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
    
    if (location_label_noedit != null)
      handle_location_label_changed(location_label_noedit);
    else
      handle_edit_location();

    var area = (Gtk.VBox)get_content_area();
    area.add(notebook);
  }
  
  void handle_edit_location()
  {
    if (location_label_noedit != null) {
      location_label_noedit.destroy();
      location_label_noedit = null;
    }
    if (location_label_button != null) {
      location_label_button.destroy();
      location_label_button = null;
    }

    var location = new DejaDup.ConfigLocation();
    location.show_all();
    location.changed.connect(handle_location_changed);
    location_hbox.add(location);
    handle_location_changed(location);
  }

  void handle_location_label_changed(DejaDup.ConfigWidget location)
  {
    for (int i = 0; i < NUM_LISTS; ++i) {
      bool show = false;
      if (i == S3_LIST && ((DejaDup.ConfigLabelLocation)location).is_s3)
        show = true;
      
      foreach (Gtk.Widget w in backend_widgets[i]) {
        w.no_show_all = !show;
        if (show)
          w.show_all();
        else
          w.hide();
      }
    }
  }

  void handle_location_changed(DejaDup.ConfigWidget location)
  {
    for (int i = 0; i < NUM_LISTS; ++i) {
      bool show = false;
      if (i == S3_LIST && ((DejaDup.ConfigLocation)location).is_s3)
        show = true;
      
      foreach (Gtk.Widget w in backend_widgets[i]) {
        w.no_show_all = !show;
        if (show)
          w.show_all();
        else
          w.hide();
      }
    }
  }
  
  void handle_response(Gtk.Dialog dlg, int response) {
    switch (response) {
    case Gtk.ResponseType.HELP:
      DejaDup.show_uri(dlg, "ghelp:deja-dup#prefs");
      break;
    default:
      hide();
      Idle.add(() => {destroy(); return false;});
      break;
    }
  }
}

