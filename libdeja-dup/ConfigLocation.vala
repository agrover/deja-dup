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

public class ConfigLocation : ConfigWidget
{
  public signal void changed();
  
  public bool is_s3 {get; private set;}
  
  Gtk.FileChooserDialog dialog;
  Gtk.FileChooserButton button;
  File top_tmpdir;
  File tmpdir;
  string s3_name;
  construct {
    dialog = new Gtk.FileChooserDialog (_("Select Backup Location"), null,
                          						  Gtk.FileChooserAction.SELECT_FOLDER,
                          						  Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                          						  Gtk.STOCK_OPEN, Gtk.ResponseType.ACCEPT);
    dialog.set_default_response(Gtk.ResponseType.ACCEPT);
    
    button = new Gtk.FileChooserButton.with_dialog(dialog);
    button.local_only = false;
    add(button);
    
    s3_name = _("Amazon S3");
    add_special_location();
    
    set_from_config();
    button.selection_changed.connect(handle_selection_changed);
  }
  
  ~ConfigLocation()
  {
    try {
      tmpdir.delete(null);
      top_tmpdir.delete(null);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  File get_file_from_gconf() throws Error
  {
    // Check the backend type, then GIO uri if needed
    File file = null;
    var val = client.get_string(BACKEND_KEY);
    if (val == "s3" && tmpdir != null)
      file = tmpdir;
    else {
      val = client.get_string(GIO_LOCATION_KEY);
      if (val == null)
        val = ""; // current directory
      file = File.parse_name(val);
    }
    return file;
  }
  
  protected override void set_from_config()
  {
    // Check the backend type, then GIO uri if needed
    File file = null;
    try {
      var uri = button.get_uri();
      var button_file = uri == null ? null : File.new_for_uri(uri);
      file = get_file_from_gconf();
      if (button_file == null || !file.equal(button_file)) {
        button.select_uri(file.get_uri());
        is_s3 = tmpdir != null && file.equal(tmpdir);
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  void handle_selection_changed()
  {
    File gconf_file = null;
    try {
      gconf_file = get_file_from_gconf();
    }
    catch (Error e) {} // ignore
    
    var uri = button.get_uri();
    var file = uri == null ? null : File.new_for_uri(uri);
    if (file == null || file.equal(gconf_file))
      return; // we sometimes get several selection changed notices in a row...
    
    is_s3 = tmpdir != null && file.equal(tmpdir);
    
    try {
      if (tmpdir != null && file.equal(tmpdir))
        client.set_string(BACKEND_KEY, "s3");
      else {
        client.set_string(BACKEND_KEY, "gio");
        client.set_string(GIO_LOCATION_KEY, file.get_parse_name());
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    changed();
  }
  
  void add_special_location()
  {
    // This is a big ol' hack to show a custom, non-GIO name as a location,
    // Should try to get S3 in as a patch to GIO someday...
    var template = Path.build_filename(Environment.get_tmp_dir(), "deja-dup-XXXXXX");
    top_tmpdir = File.new_for_path(DirUtils.mkdtemp(template));
    tmpdir = top_tmpdir.get_child(s3_name);
    
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
    if (is_s3) {
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

