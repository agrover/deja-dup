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

public class Preferences : Gtk.Grid
{
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
    var page = new Gtk.Alignment(0.0f, 0.5f, 1.0f, 0.0f);

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
      this.remove(page);
      this.add(make_settings_page());
      this.show_all();
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

    page.add(hbox);

    continue_button.set("has-focus", true);

    page.border_width = 18;
    page.show();
    return page;
  }

  Gtk.Widget make_settings_page()
  {
    var settings_page = new Gtk.Grid();
    Gtk.Notebook notebook = new Gtk.Notebook();
    Gtk.Widget w;
    Gtk.Label label;
    Gtk.Grid table;
    int row;
    Gtk.SizeGroup label_sizes;

    var settings = DejaDup.get_settings();

    var outer_table = new Gtk.Grid();
    outer_table.orientation = Gtk.Orientation.VERTICAL;
    outer_table.row_spacing = 6;
    outer_table.border_width = 12;

    table = new Gtk.Grid();
    table.orientation = Gtk.Orientation.VERTICAL;
    table.row_spacing = 6;
    table.column_spacing = 12;
    table.expand = true;
    outer_table.add(table);

    row = 0;
    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);

    var align = new Gtk.Alignment(0.0f, 0.5f, 0.0f, 0.0f);
    var @switch = new Gtk.Switch();
    settings.bind(DejaDup.PERIODIC_KEY, @switch, "active", SettingsBindFlags.DEFAULT);
    align.add(@switch);
    label = new Gtk.Label.with_mnemonic(_("_Automatic backup"));
    label.mnemonic_widget = @switch;
    label.xalign = 1.0f;
    table.attach(label, 0, row, 1, 1);
    table.attach(align, 1, row, 1, 1);
    ++row;

    w = new Gtk.Grid(); // spacer
    w.height_request = 12; // plus 6 pixels on either side
    table.attach(w, 0, row, 2, 1);
    ++row;

    w = new DejaDup.ConfigLabelLocation();
    w.set("hexpand", true);
    label = new Gtk.Label(_("Backup location"));
    label.set("xalign", 1.0f,
              "yalign", 0.0f);
    label_sizes.add_widget(label);

    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    label = new Gtk.Label(_("Folders to back up"));
    label.set("xalign", 1.0f, "yalign", 0.0f);
    label_sizes.add_widget(label);
    w = new DejaDup.ConfigLabelList(DejaDup.INCLUDE_LIST_KEY);
    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    label = new Gtk.Label(_("Folders to ignore"));
    label.set("xalign", 1.0f, "yalign", 0.0f);
    label_sizes.add_widget(label);
    w = new DejaDup.ConfigLabelList(DejaDup.EXCLUDE_LIST_KEY);
    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    w = new Gtk.Grid(); // spacer
    w.height_request = 12; // plus 6 pixels on either side
    table.attach(w, 0, row, 2, 1);
    ++row;

    var bdate_label = new Gtk.Label(_("Last backup"));
    bdate_label.xalign = 1.0f;
    var bdate = new DejaDup.ConfigLabelBackupDate(DejaDup.ConfigLabelBackupDate.Kind.LAST);
    bdate.bind_property("sensitive", bdate_label, "sensitive", BindingFlags.SYNC_CREATE);
    table.attach(bdate_label, 0, row, 1, 1);
    table.attach(bdate, 1, row, 1, 1);
    ++row;

    var ndate_label = new Gtk.Label(_("Next backup"));
    ndate_label.xalign = 1.0f;
    var ndate = new DejaDup.ConfigLabelBackupDate(DejaDup.ConfigLabelBackupDate.Kind.NEXT);
    ndate.bind_property("sensitive", ndate_label, "sensitive", BindingFlags.SYNC_CREATE);
    table.attach(ndate_label, 0, row, 1, 1);
    table.attach(ndate, 1, row, 1, 1);
    ++row;

    var bbox = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
    bbox.layout_style = Gtk.ButtonBoxStyle.CENTER;
    bbox.spacing = 12;
    outer_table.add(bbox);

    w = new Gtk.Button.with_mnemonic(_("_Restore…"));
    (w as Gtk.Button).clicked.connect((b) => {
      run_deja_dup("--restore", b.get_display().get_app_launch_context());
    });
    restore_button = w;
    bbox.add(w);
    w = new Gtk.Button.with_mnemonic(_("Back Up"));
    (w as Gtk.Button).clicked.connect((b) => {
      run_deja_dup("--backup", b.get_display().get_app_launch_context());
    });
    backup_button = w;
    bbox.add(w);

    bus_watch_id = Bus.watch_name(BusType.SESSION, "org.gnome.DejaDup.Operation",
                                  BusNameWatcherFlags.NONE,
                                  () => {restore_button.sensitive = false;
                                         backup_button.sensitive = false;},
                                  () => {restore_button.sensitive = true;
                                         backup_button.sensitive = true;});

    notebook.append_page(outer_table, null);
    notebook.set_tab_label_text(outer_table, _("Overview"));

    // Reset page
    table = new Gtk.Grid();
    table.row_spacing = 6;
    table.column_spacing = 12;
    table.border_width = 12;
    row = 0;

    var location = new DejaDup.ConfigLocation(label_sizes);
    label = new Gtk.Label(_("_Storage location"));
    label.set("mnemonic-widget", location,
              "use-underline", true,
              "xalign", 1.0f);
    label_sizes.add_widget(label);

    table.attach(label, 0, row, 1, 1);
    table.attach(location, 1, row, 1, 1);
    location.set("hexpand", true);
    ++row;

    location.extras.set("hexpand", true);
    table.attach(location.extras, 0, row, 2, 1);
    ++row;

    notebook.append_page(table, null);
    // Translators: storage as in "where to store the backup"
    notebook.set_tab_label_text(table, _("Storage"));

    // Now make sure to reserve the excess space that the hidden bits of
    // ConfigLocation will need.
    Gtk.Requisition req, hidden;
    table.show_all();
    table.get_preferred_size(null, out req);
    hidden = location.hidden_size();
    req.width = req.width + hidden.width;
    req.height = req.height + hidden.height;
    table.set_size_request(req.width, req.height);

    // Reset page
    table = new Gtk.Grid();
    table.row_spacing = 6;
    table.column_spacing = 12;
    table.border_width = 12;
    table.column_homogeneous = true;
    
    w = new DejaDup.ConfigList(DejaDup.INCLUDE_LIST_KEY);
    w.set("expand", true);
    label = new Gtk.Label(_("Folders to _back up"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f,
              "yalign", 0.0f);
    table.attach(label, 0, 0, 1, 1);
    table.attach(w, 0, 1, 1, 1);
    
    w = new DejaDup.ConfigList(DejaDup.EXCLUDE_LIST_KEY);
    w.set("expand", true);
    label = new Gtk.Label(_("Folders to _ignore"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f,
              "yalign", 0.0f);
    table.attach(label, 1, 0, 1, 1);
    table.attach(w, 1, 1, 1, 1);
    
    notebook.append_page(table, null);
    notebook.set_tab_label_text(table, _("Folders"));
    
    // Reset page
    table = new Gtk.Grid();
    table.row_spacing = 6;
    table.column_spacing = 12;
    table.border_width = 12;
    table.halign = Gtk.Align.CENTER;
    row = 0;

    align = new Gtk.Alignment(0.0f, 0.5f, 0.0f, 0.0f);
    @switch = new Gtk.Switch();
    settings.bind(DejaDup.PERIODIC_KEY, @switch, "active", SettingsBindFlags.DEFAULT);
    align.add(@switch);
    label = new Gtk.Label.with_mnemonic(_("_Automatic backup"));
    label.mnemonic_widget = @switch;
    label.xalign = 1.0f;
    table.attach(label, 0, row, 1, 1);
    table.attach(align, 1, row, 1, 1);
    ++row;

    w = new DejaDup.ConfigPeriod(DejaDup.PERIODIC_PERIOD_KEY);
    w.hexpand = true;
    settings.bind(DejaDup.PERIODIC_KEY, w, "sensitive", SettingsBindFlags.DEFAULT);
    label = new Gtk.Label.with_mnemonic(_("_Every"));
    label.mnemonic_widget = w;
    label.xalign = 1.0f;
    settings.bind(DejaDup.PERIODIC_KEY, label, "sensitive", SettingsBindFlags.DEFAULT);
    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    w = new DejaDup.ConfigDelete(DejaDup.DELETE_AFTER_KEY);
    w.hexpand = true;
    label = new Gtk.Label.with_mnemonic(_("_Keep"));
    label.mnemonic_widget = w;
    label.xalign = 1.0f;
    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    label = new Gtk.Label(_("Old backups will be deleted earlier if the storage location is low on space."));
    var attrs = new Pango.AttrList();
    attrs.insert(Pango.attr_style_new(Pango.Style.ITALIC));
    label.set_attributes(attrs);
    label.wrap = true;
    label.max_width_chars = 25;
    table.attach(label, 1, row, 1, 1);
    ++row;

    notebook.append_page(table, null);
    notebook.set_tab_label_text(table, _("Scheduling"));

    var accessible = notebook.get_accessible();
    if (accessible != null)
      accessible.set_name(_("Categories"));

    notebook.expand = true;
    settings_page.add(notebook);

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
    if (should_show_welcome())
      add(make_welcome_page());
    else
      add(make_settings_page());
    set_size_request(-1, 400);
  }
}

}
