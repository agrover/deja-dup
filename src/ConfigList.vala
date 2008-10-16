/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008 Michael Terry <mike@mterry.name>

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

public class ConfigList : ConfigWidget
{
  public ConfigList(string key)
  {
    this.key = key;
  }
  
  Gtk.TreeView tree;
  Gtk.Button add_button;
  Gtk.Button remove_button;
  construct {
    var model = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(Icon));
    tree = new Gtk.TreeView();
    tree.set("model", model,
             "headers-visible", false);
    
    tree.insert_column_with_attributes(-1, null, new Gtk.CellRendererPixbuf(),
                                       "gicon", 2);
    
    var renderer = new Gtk.CellRendererText();
    tree.insert_column_with_attributes(-1, null, renderer,
                                       "text", 1);
    
    add_button = new Gtk.Button.from_stock(Gtk.STOCK_ADD);
    add_button.clicked += handle_add;
    
    remove_button = new Gtk.Button.from_stock(Gtk.STOCK_REMOVE);
    remove_button.clicked += handle_remove;
    
    var hbox = new Gtk.HBox(false, 6);
    var vbox = new Gtk.VBox(false, 6);
    
    vbox.pack_start(add_button, false, false, 0);
    vbox.pack_start(remove_button, false, false, 0);
    hbox.add(tree);
    hbox.pack_start(vbox, false, false, 0);
    add(hbox);
    
    set_from_config();
    handle_selection_change(tree.get_selection());
    tree.get_selection().changed += handle_selection_change;
  }
  
  protected override void set_from_config()
  {
    weak SList<string> slist;
    try {
      slist = client.get_list(key, GConf.ValueType.STRING);
    }
    catch (Error e) {
      printerr("%s\n", e.message);
      return;
    }
    
    var list = parse_dir_list(slist);
    
    Gtk.ListStore model;
    tree.get("model", out model);
    model.clear();
    
    int i = 0;
    File home = File.new_for_path(Environment.get_home_dir());
    File trash = File.new_for_path(get_trash_path());
    foreach (File f in list) {
      string s;
      if (f.equal(home))
        s = _("Home Folder");
      else if (f.equal(trash))
        s = _("Trash");
      else if (f.has_prefix(home))
        s = home.get_relative_path(f);
      else
        s = f.get_path();
      
      Gtk.TreeIter iter;
      model.insert_with_values(out iter, i++, 0, f.get_path(), 1, s);
      
      // If the folder is the trash, look up icon especially.  For some
      // reason, gio doesn't do it for us.
      Icon icon = null;
      if (f.equal(trash)) {
        string[] names = {"user-trash", "folder"};
        icon = new ThemedIcon.from_names(names, 2);
      }
      else {
        try {
          FileInfo info = f.query_info(FILE_ATTRIBUTE_STANDARD_ICON, FileQueryInfoFlags.NONE, null);
          icon = info.get_icon();
        }
        catch (Error e) {
          printerr("%s\n", e.message);
        }
      }
      if (icon != null)
        model.set(iter, 2, icon);
    }
  }
  
  void handle_selection_change(Gtk.TreeSelection sel)
  {
    var empty = sel.count_selected_rows() == 0;
    remove_button.set_sensitive(!empty);
  }
  
  void handle_add()
  {
    var dlg = new Gtk.FileChooserDialog(_("Choose folder"),
                                        (Gtk.Window)get_toplevel(),
                                        Gtk.FileChooserAction.SELECT_FOLDER,
                                        Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                          				      Gtk.STOCK_OPEN, Gtk.ResponseType.ACCEPT);
    
    if (dlg.run() != Gtk.ResponseType.ACCEPT) {
      return;
    }
    
    var folder = File.new_for_path(dlg.get_filename());
    dlg.hide();
    
    weak SList<string> slist;
    try {
      slist = client.get_list(key, GConf.ValueType.STRING);
      bool found = false;
      foreach (string s in slist) {
        var sfile = File.new_for_path(s);
        if (sfile.equal(folder)) {
          found = true;
          break;
        }
      }
      
      if (!found) {
        slist.append(folder.get_path());
        client.set_list(key, GConf.ValueType.STRING, slist);
      }
      else {
        var msgdlg = new Gtk.MessageDialog((Gtk.Window)get_toplevel(),
                                           Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                           Gtk.MessageType.ERROR,
                                           Gtk.ButtonsType.OK,
                                           _("Could not add the folder"));
        msgdlg.format_secondary_text("%s is already in the list".printf(folder.get_path()));
        msgdlg.run();
        msgdlg.destroy();
      }
    }
    catch (Error e) {
      printerr("%s\n", e.message);
      return;
    }
  }
  
  void handle_remove()
  {
    var sel = tree.get_selection();
    
    weak Gtk.TreeModel model;
    Gtk.TreeIter iter;
    if (!sel.get_selected(out model, out iter))
      return;
    
    string current;
    model.get(iter, 0, out current);
    var current_file = File.new_for_path(current);
    
    try {
      weak SList<string> slist = client.get_list(key, GConf.ValueType.STRING);
      weak SList<string> iter = slist;
      while (iter != null) {
        var sfile = parse_dir(iter.data);
        if (sfile.equal(current_file)) {
          slist.remove_link(iter);
          client.set_list(key, GConf.ValueType.STRING, slist);
          break;
        }
        iter = iter.next;
      }
    }
    catch (Error e) {
      printerr("%s\n", e.message);
      return;
    }
  }
}

