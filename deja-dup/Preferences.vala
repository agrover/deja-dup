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
  public DejaDup.PreferencesPeriodicSwitch external_auto_switch {get; set; default = null;}
  public bool duplicity_installed {get; private set; default = false;}

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
  Gtk.ProgressBar backup_progress;
  DejaDup.ConfigLabelDescription restore_desc;
  Gtk.Button restore_button;
  Gtk.ProgressBar restore_progress;
  DejaDup.PreferencesPeriodicSwitch auto_switch;
  const int PAGE_HMARGIN = 24;
  const int PAGE_VMARGIN = 12;

  public Preferences(DejaDup.PreferencesPeriodicSwitch? auto_switch)
  {
    Object(external_auto_switch: auto_switch);

    // Set initial switch sensitivity, but for some odd reason we can't set
    // this earlier.  Even if at the end of the constructor, it gets reset...
    external_auto_switch.sensitive = duplicity_installed;
  }

  async void install_duplicity()
  {
    backup_button.sensitive = false;
    restore_button.sensitive = false;

    try {
      var task = new Pk.Task();
      var results = yield task.resolve_async(Pk.Filter.NOT_INSTALLED, {"duplicity"}, null, () => {});
      if (results != null && results.get_error_code () == null)
      {
        // Convert from List to array (I don't know why the API couldn't be friendlier...)
        var package_array = results.get_package_array();
        var package_ids = new string[0];
        var package_names = new GenericSet<string>(str_hash, str_equal);
        for (var i = 0; i < package_array.length; i++) {
          // First make sure we haven't added packages with this name already, which can happen
          // if the user has multiple arch repositories enabled (like amd64 and i386). We could
          // instead simply take the first result, but we want to make it easy for distros to
          // patch the above resolve_async line to have multiple packages if they want.
          if (!package_names.contains(package_array.data[i].get_name())) {
            package_names.add(package_array.data[i].get_name());
            package_ids += package_array.data[i].get_id();
          }
        }

        yield task.install_packages_async(package_ids, null, (p, t) => {
          backup_progress.fraction = p.percentage / 100.0;
          restore_progress.fraction = p.percentage / 100.0;
        });

        duplicity_installed = Environment.find_program_in_path("duplicity") != null;
        if (duplicity_installed) {
          backup_desc.everything_installed = true;
          backup_button.label = _("_Back Up Now…");
          restore_desc.everything_installed = true;
          restore_button.label = _("_Restore…");
          auto_switch.sensitive = true;
          external_auto_switch.sensitive = true;
        }
      }
    }
    catch (Error e) {
      // We don't want to show authorization errors -- either the user clicked
      // cancel or already entered password several times.  Don't need to warn them.
      // Oddly enough, I couldn't get error matching to work for this.  Maybe the
      // policykit bindings I copied are incomplete.
      if (e.message.contains("org.freedesktop.PolicyKit.Error.NotAuthorized")) {
        warning("%s\n", e.message);
      } else {
        Gtk.MessageDialog dlg = new Gtk.MessageDialog (get_toplevel() as Gtk.Window,
            Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
            Gtk.MessageType.ERROR,
            Gtk.ButtonsType.OK,
            "%s", _("Could not install"));
        dlg.format_secondary_text("%s", e.message);
        dlg.run();
        destroy_widget(dlg);
      }
    }

    backup_progress.visible = false;
    restore_progress.visible = false;
    backup_button.sensitive = true;
    restore_button.sensitive = true;
  }

  Gtk.Widget make_settings_page()
  {
    var settings_page = new Gtk.Grid();
    Gtk.Notebook notebook = new Gtk.Notebook();
    Gtk.Widget w;
    Gtk.Label label;
    Gtk.Grid table;
    Gtk.TreeIter iter;
    int i = 0;
    int row;
    Gtk.SizeGroup label_sizes;

    var settings = DejaDup.get_settings();

    settings_page.column_spacing = 12;

    var cat_model = new Gtk.ListStore(2, typeof(string), typeof(int));
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
      int page;
      if (tree.get_selection().get_selected(null, out sel_iter)) {
        cat_model.get(sel_iter, 1, out page);
        notebook.page = page;
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

    w = new Gtk.Image.from_icon_name("deja-dup-symbolic", Gtk.IconSize.DIALOG);
    w.halign = Gtk.Align.CENTER;
    w.valign = Gtk.Align.START;
    table.attach(w, 0, row, 1, 3);
    w = new DejaDup.ConfigLabelBackupDate(DejaDup.ConfigLabelBackupDate.Kind.LAST);
    w.halign = Gtk.Align.START;
    w.valign = Gtk.Align.START;
    table.attach(w, 1, row, 2, 1);
    ++row;

    w = new DejaDup.ConfigLabelDescription(DejaDup.ConfigLabelDescription.Kind.RESTORE, duplicity_installed);
    w.halign = Gtk.Align.START;
    w.valign = Gtk.Align.START;
    restore_desc = w as DejaDup.ConfigLabelDescription;
    table.attach(w, 1, row, 2, 1);
    ++row;

    w = new Gtk.Button.with_mnemonic(duplicity_installed ? _("_Restore…") : _("_Install…"));
    w.margin_top = 6;
    w.halign = Gtk.Align.START;
    w.expand = false;
    (w as Gtk.Button).clicked.connect((b) => {
      if (duplicity_installed) {
        app.restore();
      } else {
        restore_progress.visible = true;
        install_duplicity.begin();
      }
    });
    restore_button = w as Gtk.Button;
    label_sizes.add_widget(w);
    table.attach(w, 1, row, 1, 1);
    w = new Gtk.ProgressBar();
    w.halign = Gtk.Align.START;
    w.valign = Gtk.Align.CENTER;
    w.hexpand = true;
    w.no_show_all = true;
    restore_progress = w as Gtk.ProgressBar;
    table.attach(w, 2, row, 1, 1);
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

    w = new DejaDup.ConfigLabelDescription(DejaDup.ConfigLabelDescription.Kind.BACKUP, duplicity_installed);
    w.halign = Gtk.Align.START;
    w.valign = Gtk.Align.START;
    backup_desc = w as DejaDup.ConfigLabelDescription;
    table.attach(w, 1, row, 2, 1);
    ++row;

    w = new Gtk.Button.with_mnemonic(duplicity_installed ? _("_Back Up Now…") : _("Install…"));
    w.margin_top = 6;
    w.halign = Gtk.Align.START;
    w.expand = false;
    (w as Gtk.Button).clicked.connect((b) => {
      if (duplicity_installed) {
        app.backup();
      } else {
        backup_progress.visible = true;
        install_duplicity.begin();
      }
    });
    backup_button = w as Gtk.Button;
    label_sizes.add_widget(w);
    table.attach(w, 1, row, 1, 1);
    w = new Gtk.ProgressBar();
    w.halign = Gtk.Align.START;
    w.valign = Gtk.Align.CENTER;
    w.hexpand = true;
    w.no_show_all = true;
    backup_progress = w as Gtk.ProgressBar;
    table.attach(w, 2, row, 1, 1);
    ++row;

    notebook.append_page(table, null);
    cat_model.insert_with_values(out iter, i, 0, _("Overview"), 1, i);
    ++i;

    // Reset page
    table = new_panel();

    w = new DejaDup.ConfigList(DejaDup.INCLUDE_LIST_KEY);
    w.expand = true;
    table.add(w);

    notebook.append_page(table, null);
    cat_model.insert_with_values(out iter, i, 0, _("Folders to save"), 1, i);
    ++i;

    // Reset page
    table = new_panel();

    w = new DejaDup.ConfigList(DejaDup.EXCLUDE_LIST_KEY);
    w.expand = true;
    table.add(w);

    notebook.append_page(table, null);
    cat_model.insert_with_values(out iter, i, 0, _("Folders to ignore"), 1, i);
    ++i;

    // Reset page
    table = new_panel();
    table.row_spacing = 6;
    table.column_spacing = 12;
    table.halign = Gtk.Align.CENTER;
    row = 0;

    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    var location = new DejaDup.ConfigLocation(label_sizes);
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

    notebook.append_page(table, null);
    // Translators: storage as in "where to store the backup"
    cat_model.insert_with_values(out iter, i, 0, _("Storage location"), 1, i);
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
    auto_switch = new DejaDup.PreferencesPeriodicSwitch();
    auto_switch.sensitive = duplicity_installed;
    align.add(auto_switch);
    label = new Gtk.Label.with_mnemonic(_("_Automatic backup"));
    label.mnemonic_widget = auto_switch;
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

    notebook.append_page(table, null);
    cat_model.insert_with_values(out iter, i, 0, _("Scheduling"), 1, i);
    ++i;

    notebook.show_all(); // can't switch to pages that aren't shown

    // Select first one by default
    cat_model.get_iter_first(out iter);
    tree.get_selection().select_iter(iter);

    notebook.show_tabs = false;
    notebook.show_border = false;
    notebook.expand = true;
    settings_page.add(notebook);

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
    duplicity_installed = Environment.find_program_in_path("duplicity") != null;
    add(make_settings_page());
    set_size_request(-1, 400);
  }
}

}
