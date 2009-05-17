/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008—2009 Michael Terry <mike@mterry.name>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using GLib;

namespace DejaDup {

public class ConfigFolder : ConfigWidget
{
  string special_name {get; construct};
  string special_key {get; construct};
  
  public ConfigFolder(string key, string? special_name, string? special_key)
  {
    this.key = key;
    this.special_name = special_name;
    this.special_key = special_key;
  }
  
  public bool is_special()
  {
    return tmpdir.equal(button.get_file());
  }
  
  Gtk.FileChooserDialog dialog;
  Gtk.FileChooserButton button;
  File top_tmpdir;
  File tmpdir;
  construct {
    dialog = new Gtk.FileChooserDialog (_("Select Backup Location"), null,
                          						  Gtk.FileChooserAction.SELECT_FOLDER,
                          						  Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                          						  Gtk.STOCK_OPEN, Gtk.ResponseType.ACCEPT);
    dialog.set_default_response(Gtk.ResponseType.ACCEPT);
    
    button = new Gtk.FileChooserButton.with_dialog(dialog);
    button.local_only = false;
    add(button);
    
    add_special_location();
    set_from_config();
    button.selection_changed.connect(handle_selection_changed);
  }
  
  ~ConfigFolder()
  {
    try {
      tmpdir.delete(null);
      top_tmpdir.delete(null);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  protected override void set_from_config()
  {
    string val;
    try {
      val = client.get_string(key);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return;
    }
    if (val == null)
      val = ""; // There should really be a better default, but I'm not sure
                // what.  The first mounted volume we see?  Create a directory
                // in $HOME called 'deja-dup'?
    
    if (button.get_filename() != val) {
      button.set_filename(val);
    }
  }
  
  void handle_selection_changed()
  {
    string val = null;
    try {
      val = client.get_string(key);
    }
    catch (Error e) {} // ignore
    
    string filename = button.get_filename();
    if (filename == val)
      return; // we sometimes get several selection changed notices in a row...
    
    try {
      client.set_string(key, filename);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  void add_special_location()
  {
    // This is a big ol' hack to show a custom, non-GIO name as a location,
    // Should try to get that S3 in as a patch someday...
    var template = Path.build_filename(Environment.get_tmp_dir(), "deja-dup-XXXXXX");
    top_tmpdir = File.new_for_path(DirUtils.mkdtemp(template));
    tmpdir = top_tmpdir.get_child(special_name);
    
    try {
      tmpdir.make_directory(null);
      button.add_shortcut_folder_uri(tmpdir.get_uri());
      dialog.show.connect(handle_dialog_show);
      dialog.hide.connect(handle_dialog_hide);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  void handle_dialog_show(Gtk.Widget w)
  {
    if (is_special()) {
      // We need to reset the current folder, because we don't want to expose
      // the temporary folder used for s3.  So go to $HOME.
      button.set_current_folder(Environment.get_home_dir());
    }
    
    try {
      button.remove_shortcut_folder_uri(tmpdir.get_uri());
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  void handle_dialog_hide(Gtk.Widget w)
  {
    try {
      button.add_shortcut_folder_uri(tmpdir.get_uri());
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
}

}

