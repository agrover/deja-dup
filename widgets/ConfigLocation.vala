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

namespace DejaDup {

public class ConfigLocation : ConfigWidget
{
  static const int COL_ICON = 0;
  static const int COL_TEXT = 1;
  static const int COL_SORT = 2;
  static const int COL_VOL = 3;

  int index_s3;
  int index_ssh;
  int index_smb;
  int index_vol_base;
  int index_local;

  Gtk.ComboBox button;
  Gtk.ListStore store;
  Gtk.Notebook notebook;
  Gtk.SizeGroup label_sizes;
  construct {
    var vbox = new Gtk.VBox(false, 6);
    var hbox = new Gtk.HBox(false, 6);
    add(hbox);
    
    store = new Gtk.ListStore(3, typeof(Icon), typeof(string), typeof(string), typeof(Volume));
    button = new Gtk.ComboBox.with_model(store);
    hbox.add(button);

    Gtk.TreeIter iter;
    int i = 0;

    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);

    notebook = new Gtk.Notebook();
    notebook.show_tabs = false;
    notebook.show_border = false;

    // Insert cloud providers
    index_s3 = add_entry(i++, new ThemedIcon.with_default_fallbacks("folder-remote"),
                         _("Amazon S3"), 0, new ConfigLocationS3(label_sizes));

    // Now insert remote servers
    index_ssh = add_entry(i++, new ThemedIcon.with_default_fallbacks("folder-remote"),
                          _("SSH Server"), 1, new ConfigLocationSSH(label_sizes));
    index_smb = add_entry(i++, new ThemedIcon.with_default_fallbacks("folder-remote"),
                          _("Windows Share"), 1);

    // Now insert removable drives
    index_vol_base = i;
    var mon = VolumeMonitor.get();
    mon.ref(); // bug 569418; bad things happen when VM goes away
    List<Volume> vols = mon.get_volumes();
    foreach (Volume v in vols) {
      add_entry(i++, v.get_icon(), v.get_name(), 2, null, v);
    }

    // And finally, a local folder option
    index_local = add_entry(i++, new ThemedIcon("folder"), _("Local Folder"), 3);

    store.set_sort_column_id(COL_SORT, Gtk.SortType.ASCENDING);

    var pixrenderer = new Gtk.CellRendererPixbuf();
    button.pack_start(pixrenderer, false);
    button.add_attribute(pixrenderer, "gicon", COL_ICON);

    var textrenderer = new Gtk.CellRendererText();
    button.pack_start(textrenderer, true);
    button.add_attribute(textrenderer, "text", COL_TEXT);

    // End of location combo

    mnemonic_activate.connect(on_mnemonic_activate);

    set_from_config();
    button.changed.connect(handle_changed);

    watch_key(BACKEND_KEY);
    watch_key(FILE_PATH_KEY, DejaDup.get_settings(FILE_ROOT));
  }
  
  int add_entry(int index, Icon? icon, string label, int category,
                Gtk.Widget? page = null, Volume? volume = null)
  {
    Gtk.TreeIter iter;
    store.insert_with_values(out iter, index, COL_ICON, icon, COL_TEXT, label,
                             COL_SORT, "%d%s".printf(category, label),
                             COL_VOL, volume);
    notebook.insert_page(page, null, index);
    return index;
  }

  bool on_mnemonic_activate(Gtk.Widget w, bool g)
  {
    return true;//button.mnemonic_activate(g);
  }

  protected override async void set_from_config()
  {
  }
/*
  protected override async void set_from_config()
  {
    // Check the backend type, then GIO uri if needed
    File file = null;
    try {
      var uri = button.get_uri();
      var button_file = uri == null ? null : File.new_for_uri(uri);
      file = get_file_from_settings();
      if (button_file == null || !file.equal(button_file)) {
        button.set_current_folder_uri(file.get_uri());
        is_s3 = tmpdir != null && file.equal(tmpdir);
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  */
  void handle_changed()
  {
    set_location_info();
    notebook.set_current_page(button.get_active());
  }

  async void set_location_info()
  {
    var index = button.get_active();

    if (index == index_s3) {
      settings.set_string(BACKEND_KEY, "s3");
    }
    else if (index == index_ssh) {
      settings.set_string(BACKEND_KEY, "file");
      DejaDup.get_settings(FILE_ROOT).set_string(FILE_TYPE_KEY, "normal");
      
    }
    else if (index == index_smb) {
      settings.set_string(BACKEND_KEY, "file");
      DejaDup.get_settings(FILE_ROOT).set_string(FILE_TYPE_KEY, "normal");
    }
    else if (index >= index_vol_base && index < index_local) {
      // Grab volume from model
      Gtk.TreeIter iter;
      Variant vol_var;
      if (!store.get_iter_from_string(out iter, "%i".printf(index - index_vol_base))) {
        warning("Invalid volume location index %i\n", index);
        return;
      }
      store.get_value(iter, COL_VOL, out vol_var);
      Volume vol = vol_var.get_data() as Volume;
      if (vol == null) {
        warning("Invalid volume location index %i\n", index);
        return;
      }
//      set_file_info(new File.
    }
    else if (index == index_local) {
    }
    else {
      warning("Unknown location index %i\n", index);
      return;
    }

    changed();
  }

  async void set_local_info(File file)
  {
    try {
      DejaDup.get_settings(FILE_ROOT).set_string(FILE_PATH_KEY, file.get_parse_name());
      settings.set_string(BACKEND_KEY, "file");
      yield BackendFile.check_for_volume_info(file);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }

  async void set_remote_file(string schema)
  {
  }
}

}

