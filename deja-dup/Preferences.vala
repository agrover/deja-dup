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

// Convenience class for adding automatic backup switch to pref shells
public class PreferencesPeriodicSwitch : Gtk.Switch
{
  construct
  {
    var settings = DejaDup.get_settings();
    settings.bind(DejaDup.PERIODIC_KEY, this, "active", SettingsBindFlags.DEFAULT);
  }
}

public class Preferences : Gtk.Grid
{
  DejaDupApp _app;
  public DejaDupApp app {
    get { return _app; }
    set {
      _app = value;
      _app.notify["op"].connect(() => {
        restore_button.sensitive = _app.op == null;
        backup_button.sensitive = _app.op == null;
      });
      restore_button.sensitive = _app.op == null;
      backup_button.sensitive = _app.op == null;
    }
  }

  DejaDup.ConfigLabelDescription backup_desc;
  Gtk.Button backup_button;
  DejaDup.ConfigLabelDescription restore_desc;
  Gtk.Button restore_button;
  const int PAGE_HMARGIN = 24;
  const int PAGE_VMARGIN = 12;

  Gtk.Widget make_settings_page()
  {
    var settings_page = new Gtk.Grid();
    Gtk.Stack stack = new Gtk.Stack();
    Gtk.Widget w;
    Gtk.Label label;
    Gtk.Grid table;
    Gtk.TreeIter iter;
    int row;
    int i = 0;
    string name;
    Gtk.SizeGroup label_sizes;

    var settings = DejaDup.get_settings();

    settings_page.column_spacing = 12;

    var cat_model = new Gtk.ListStore(2, typeof(string), typeof(string));
    var tree = new Gtk.TreeView.with_model(cat_model);
    var accessible = tree.get_accessible();
    if (accessible != null) {
      accessible.set_name("Categories");
      accessible.set_description(_("Categories"));
    }
    tree.headers_visible = false;
    tree.set_size_request(150, -1);
    var renderer = new Gtk.CellRendererText();
    renderer.xpad = 6;
    renderer.ypad = 6;
    tree.insert_column_with_attributes(-1, null, renderer,
                                       "text", 0);
    tree.get_selection().set_mode(Gtk.SelectionMode.SINGLE);
    tree.get_selection().changed.connect(() => {
      Gtk.TreeIter sel_iter;
      string sel_name;
      if (tree.get_selection().get_selected(null, out sel_iter)) {
        cat_model.get(sel_iter, 1, out sel_name);
        stack.visible_child_name = sel_name;
      }
    });

    var scrollwin = new Gtk.ScrolledWindow(null, null);
    scrollwin.hscrollbar_policy = Gtk.PolicyType.NEVER;
    scrollwin.vscrollbar_policy = Gtk.PolicyType.NEVER;
    scrollwin.shadow_type = Gtk.ShadowType.IN;
    scrollwin.add(tree);
    settings_page.add(scrollwin);

    table = new_panel();
    table.orientation = Gtk.Orientation.VERTICAL;
    table.row_spacing = 6;
    table.column_spacing = 12;
    table.expand = true;

    row = 0;

    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);

    w = new Gtk.Image.from_icon_name("org.gnome.DejaDup-symbolic", Gtk.IconSize.DIALOG);
    w.halign = Gtk.Align.CENTER;
    w.valign = Gtk.Align.START;
    table.attach(w, 0, row, 1, 3);
    w = new DejaDup.ConfigLabelBackupDate(DejaDup.ConfigLabelBackupDate.Kind.LAST);
    w.halign = Gtk.Align.START;
    w.valign = Gtk.Align.START;
    table.attach(w, 1, row, 2, 1);
    ++row;

    w = new DejaDup.ConfigLabelDescription(DejaDup.ConfigLabelDescription.Kind.RESTORE);
    w.halign = Gtk.Align.START;
    w.valign = Gtk.Align.START;
    restore_desc = w as DejaDup.ConfigLabelDescription;
    table.attach(w, 1, row, 2, 1);
    ++row;

    w = new Gtk.Button.with_mnemonic(_("_Restore…"));
    w.margin_top = 6;
    w.halign = Gtk.Align.START;
    w.expand = false;
    (w as Gtk.Button).clicked.connect((b) => {app.restore();});
    restore_button = w as Gtk.Button;
    label_sizes.add_widget(w);
    table.attach(w, 1, row, 1, 1);
    ++row;

    w = new Gtk.Grid(); // spacer
    w.height_request = 24; // plus 12 pixels on either side
    table.attach(w, 0, row, 2, 1);
    ++row;

    w = new Gtk.Image.from_icon_name("document-open-recent-symbolic", Gtk.IconSize.DIALOG);
    w.halign = Gtk.Align.CENTER;
    w.valign = Gtk.Align.START;
    table.attach(w, 0, row, 1, 3);
    w = new DejaDup.ConfigLabelBackupDate(DejaDup.ConfigLabelBackupDate.Kind.NEXT);
    w.halign = Gtk.Align.START;
    w.valign = Gtk.Align.START;
    table.attach(w, 1, row, 2, 1);
    ++row;

    w = new DejaDup.ConfigLabelDescription(DejaDup.ConfigLabelDescription.Kind.BACKUP);
    w.halign = Gtk.Align.START;
    w.valign = Gtk.Align.START;
    backup_desc = w as DejaDup.ConfigLabelDescription;
    table.attach(w, 1, row, 2, 1);
    ++row;

    w = new Gtk.Button.with_mnemonic(_("_Back Up Now…"));
    w.margin_top = 6;
    w.halign = Gtk.Align.START;
    w.expand = false;
    (w as Gtk.Button).clicked.connect((b) => {app.backup();});
    backup_button = w as Gtk.Button;
    label_sizes.add_widget(w);
    table.attach(w, 1, row, 1, 1);
    ++row;

    name = "overview";
    stack.add_named(table, name);
    cat_model.insert_with_values(out iter, i, 0, _("Overview"), 1, name);
    ++i;

    // Reset page
    table = new_panel();

    w = new DejaDup.ConfigList(DejaDup.INCLUDE_LIST_KEY);
    w.expand = true;
    table.add(w);

    name = "include";
    stack.add_named(table, name);
    cat_model.insert_with_values(out iter, i, 0, _("Folders to save"), 1, name);
    ++i;

    // Reset page
    table = new_panel();

    w = new DejaDup.ConfigList(DejaDup.EXCLUDE_LIST_KEY);
    w.expand = true;
    table.add(w);

    name = "exclude";
    stack.add_named(table, name);
    cat_model.insert_with_values(out iter, i, 0, _("Folders to ignore"), 1, name);
    ++i;

    // Reset page
    table = new_panel();
    table.row_spacing = 6;
    table.column_spacing = 12;
    table.halign = Gtk.Align.CENTER;
    row = 0;

    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    var location = new DejaDup.ConfigLocation(false, false, label_sizes);
    label = new Gtk.Label(_("_Storage location"));
    label.mnemonic_widget = location;
    label.use_underline = true;
    label.xalign = 1.0f;
    label_sizes.add_widget(label);

    table.attach(label, 0, row, 1, 1);
    table.attach(location, 1, row, 1, 1);
    location.hexpand = true;
    ++row;

    location.extras.hexpand = true;
    table.attach(location.extras, 0, row, 2, 1);
    ++row;

    name = "storage";
    stack.add_named(table, name);
    // Translators: storage as in "where to store the backup"
    cat_model.insert_with_values(out iter, i, 0, _("Storage location"), 1, name);
    ++i;

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
    table = new_panel();
    table.row_spacing = 6;
    table.column_spacing = 12;
    table.halign = Gtk.Align.CENTER;
    row = 0;

    var align = new Gtk.Alignment(0.0f, 0.5f, 0.0f, 0.0f);
    w = new DejaDup.PreferencesPeriodicSwitch();
    align.add(w);
    label = new Gtk.Label.with_mnemonic(_("_Automatic backup"));
    label.mnemonic_widget = w;
    label.xalign = 1.0f;
    table.attach(label, 0, row, 1, 1);
    table.attach(align, 1, row, 1, 1);
    ++row;

    w = new DejaDup.ConfigPeriod(DejaDup.PERIODIC_PERIOD_KEY);
    w.hexpand = true;
    settings.bind(DejaDup.PERIODIC_KEY, w, "sensitive", SettingsBindFlags.GET);
    // translators: as in "Every day"
    label = new Gtk.Label.with_mnemonic(_("_Every"));
    label.mnemonic_widget = w;
    label.xalign = 1.0f;
    settings.bind(DejaDup.PERIODIC_KEY, label, "sensitive", SettingsBindFlags.GET);
    table.attach(label, 0, row, 1, 1);
    table.attach(w, 1, row, 1, 1);
    ++row;

    w = new DejaDup.ConfigDelete(DejaDup.DELETE_AFTER_KEY);
    w.hexpand = true;
    label = new Gtk.Label.with_mnemonic(C_("verb", "_Keep"));
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

    name = "schedule";
    stack.add_named(table, name);
    cat_model.insert_with_values(out iter, i, 0, _("Scheduling"), 1, name);
    ++i;

    stack.show_all(); // can't switch to pages that aren't shown

    // Select first one by default
    cat_model.get_iter_first(out iter);
    tree.get_selection().select_iter(iter);

    stack.expand = true;
    settings_page.add(stack);

    settings_page.show();
    return settings_page;
  }

  Gtk.Grid new_panel()
  {
    var table = new Gtk.Grid();
    table.margin_left = PAGE_HMARGIN;
    table.margin_right = PAGE_HMARGIN;
    table.margin_top = PAGE_VMARGIN;
    table.margin_bottom = PAGE_VMARGIN;
    return table;
  }

  construct {
    add(make_settings_page());
    set_size_request(-1, 400);
  }
}

}
