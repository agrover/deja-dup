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
  public bool is_s3 {get; private set;}
  public bool is_u1 {get; private set;}
  
  static const int CONNECT_ID = 1;
  
  Gtk.FileChooserDialog dialog;
  Gtk.FileChooserButton button;
  File top_tmpdir;
  File s3_dir;
  File u1_dir;
  construct {
    var hbox = new Gtk.HBox(false, 6);
    add(hbox);
    
    dialog = new Gtk.FileChooserDialog (_("Select Backup Location"), null,
                          						  Gtk.FileChooserAction.SELECT_FOLDER,
                                        null);
    
    var has_connect_prog = Environment.find_program_in_path("nautilus-connect-server") != null;
    if (has_connect_prog) {
      var button = new ButtonConnect();
      var action_area = (Gtk.Box)dialog.get_action_area();
      action_area.pack_end(button, false, false, 0);
      button.show_all();
    }
    
    dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                       Gtk.STOCK_OPEN, Gtk.ResponseType.ACCEPT);
    dialog.set_default_response(Gtk.ResponseType.ACCEPT);
    dialog.show.connect(handle_dialog_show);
    dialog.hide.connect(handle_dialog_hide);
    
    button = new Gtk.FileChooserButton.with_dialog(dialog);
    button.local_only = false;
    hbox.add(button);
    
    if (has_connect_prog) {
      var connect_button = new ButtonConnect();
      hbox.add(connect_button);
    }
    
    mnemonic_activate.connect(on_mnemonic_activate);

    var template = Path.build_filename(Environment.get_tmp_dir(), "deja-dup-XXXXXX");
    top_tmpdir = File.new_for_path(DirUtils.mkdtemp(template));

    s3_dir = add_special_location(_("Amazon S3"));
    if (BackendUbuntuOne.is_available())
      u1_dir = add_special_location(_("Ubuntu One"));
    
    set_from_config();
    button.selection_changed.connect(handle_selection_changed);
    
    watch_key(BACKEND_KEY);
    watch_key(FILE_PATH_KEY, DejaDup.get_settings(FILE_ROOT));
  }
  
  ~ConfigLocation()
  {
    var del = new RecursiveDelete(top_tmpdir);
    del.start();
  }

  bool on_mnemonic_activate(Gtk.Widget w, bool g)
  {
    return button.mnemonic_activate(g);
  }

  File get_file_from_settings() throws Error
  {
    // Check the backend type, then GIO uri if needed
    File file = null;
    var val = Backend.get_default_type();
    if (val == "s3" && s3_dir != null)
      file = s3_dir;
    else if (val == "u1" && u1_dir != null)
      file = u1_dir;
    else {
      val = DejaDup.get_settings(FILE_ROOT).get_string(FILE_PATH_KEY);
      if (val == null)
        val = ""; // current directory
      file = File.parse_name(val);
    }
    return file;
  }
  
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
        is_s3 = s3_dir != null && file.equal(s3_dir);
        is_u1 = u1_dir != null && file.equal(u1_dir);
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  void handle_selection_changed()
  {
    set_file_info();
  }

  async void set_file_info()
  {
    File settings_file = null;
    try {
      settings_file = get_file_from_settings();
    }
    catch (Error err) {} // ignore
    
    var uri = button.get_uri();
    var file = uri == null ? null : File.new_for_uri(uri);
    if (file == null || file.equal(settings_file))
      return; // we sometimes get several selection changed notices in a row...
    
    is_s3 = s3_dir != null && file.equal(s3_dir);
    is_u1 = u1_dir != null && file.equal(u1_dir);
    
    try {
      if (is_s3)
        settings.set_string(BACKEND_KEY, "s3");
      else if (is_u1)
        settings.set_string(BACKEND_KEY, "u1");
      else {
        DejaDup.get_settings(FILE_ROOT).set_string(FILE_PATH_KEY, file.get_parse_name());
        settings.set_string(BACKEND_KEY, "file");
        yield BackendFile.check_for_volume_info(file);
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    changed();
  }
  
  File? add_special_location(string name)
  {
    // This is a big ol' hack to show a custom, non-GIO name as a location,
    // Should try to get S3 in as a patch to GIO someday...
    var tmpdir = top_tmpdir.get_child(name);
    
    try {
      tmpdir.make_directory(null);
      button.add_shortcut_folder_uri(tmpdir.get_uri());
      return tmpdir;
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return null;
    }
  }
  
  void handle_dialog_show(Gtk.Widget w)
  {
    if (is_s3 || is_u1) {
      // We need to reset the current folder, because we don't want to expose
      // the temporary folder used for s3.  So go to $HOME.
      button.set_current_folder(Environment.get_home_dir());
    }
    
    try {
      button.remove_shortcut_folder_uri(s3_dir.get_uri());
      button.remove_shortcut_folder_uri(u1_dir.get_uri());
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  void handle_dialog_hide(Gtk.Widget w)
  {
    try {
      button.add_shortcut_folder_uri(s3_dir.get_uri());
      button.add_shortcut_folder_uri(u1_dir.get_uri());
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
}

}

