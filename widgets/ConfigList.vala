/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008,2009 Michael Terry <mike@mterry.name>

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

public class ConfigList : ConfigWidget
{
  public Gtk.SizeGroup? size_group {get; construct;}
  
  public ConfigList(string key, Gtk.SizeGroup? sg = null)
  {
    this.size_group = sg;
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
    add_button.clicked.connect(handle_add);
    
    remove_button = new Gtk.Button.from_stock(Gtk.STOCK_REMOVE);
    remove_button.clicked.connect(handle_remove);

    if (size_group != null) {
      size_group.add_widget(add_button);
      size_group.add_widget(remove_button);
    }

    var scroll = new Gtk.ScrolledWindow(null, null);
    scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
    scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
    
    var hbox = new Gtk.HBox(false, 6);
    var vbox = new Gtk.VBox(false, 6);
    
    vbox.pack_start(add_button, false, false, 0);
    vbox.pack_start(remove_button, false, false, 0);
    scroll.add(tree);
    hbox.add(scroll);
    hbox.pack_start(vbox, false, false, 0);
    add(hbox);
    
    var selection = tree.get_selection();
    selection.set_mode(Gtk.SelectionMode.MULTIPLE);
    
    mnemonic_activate.connect((w, g) => {return tree.mnemonic_activate(g);});
    key_press_event.connect((w, e) => {
      uint modifiers = Gtk.accelerator_get_default_mod_mask();
      
      // Vala keysym bindings would be nice.  Check for delete or kp_delete
      if ((e.keyval == 0xffff || e.keyval == 0xff9f) && modifiers == 0) {
        handle_remove();
        return true;
      }
      else
        return false;
    });
    
    set_from_config();
    handle_selection_change(selection);
    selection.changed.connect(handle_selection_change);
  }
  
  protected override void set_from_config()
  {
    weak SList<string> slist;
    try {
      slist = client.get_list(key, GConf.ValueType.STRING);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return;
    }
    
    var list = DejaDup.parse_dir_list(slist);
    
    Gtk.ListStore model;
    tree.get("model", out model);
    model.clear();
    
    int i = 0;
    File home = File.new_for_path(Environment.get_home_dir());
    File trash = File.new_for_path(DejaDup.get_trash_path());
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
        // Until vala bug #564062 is fixed, we use append.  Else I'd use from_names
        icon = new ThemedIcon("user-trash");
        ((ThemedIcon)icon).append_name("folder");
      }
      else {
        try {
          FileInfo info = f.query_info(FILE_ATTRIBUTE_STANDARD_ICON, FileQueryInfoFlags.NONE, null);
          icon = info.get_icon();
        }
        catch (Error e) {
          warning("%s\n", e.message);
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
    var dlg = new Gtk.FileChooserDialog(_("Choose folders"),
                                        (Gtk.Window)get_toplevel(),
                                        Gtk.FileChooserAction.SELECT_FOLDER,
                                        Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                          				      Gtk.STOCK_OPEN, Gtk.ResponseType.ACCEPT);
    dlg.select_multiple = true;
    
    if (dlg.run() != Gtk.ResponseType.ACCEPT) {
      dlg.destroy();
      return;
    }
    
    SList<string> files = dlg.get_filenames();
    dlg.destroy();
    
    weak SList<string> slist;
    try {
      slist = client.get_list(key, GConf.ValueType.STRING);
      
      foreach (string file in files) {
        var folder = File.new_for_path(file);
        bool found = false;
        foreach (string s in slist) {
          var sfile = File.new_for_path(s);
          if (sfile.equal(folder)) {
            found = true;
            break;
          }
        }
        
        if (!found)
          slist.append(file);
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
      slist = files;
    }
    
    try {
      client.set_list(key, GConf.ValueType.STRING, slist);
    }
    catch (Error e) {warning("%s\n", e.message);}
  }
  
  void handle_remove()
  {
    var sel = tree.get_selection();
    
    weak Gtk.TreeModel model;
    List<Gtk.TreePath> paths = sel.get_selected_rows(out model);
    if (paths == null)
      return;
    
    weak SList<string> slist;
    try {
      slist = client.get_list(key, GConf.ValueType.STRING);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return;
    }
    
    foreach (Gtk.TreePath path in paths) {
      Gtk.TreeIter iter;
      if (!model.get_iter(out iter, path))
        continue;
      
      string current;
      model.get(iter, 0, out current);
      var current_file = File.new_for_path(current);
      
      weak SList<string> siter = slist, snext;
      while (siter != null) {
        snext = siter.next;
        var sfile = DejaDup.parse_dir(siter.data);
        if (sfile.equal(current_file)) {
          slist.remove_link(siter);
          break;
        }
        siter = snext;
      }
    }
    
    try {
      client.set_list(key, GConf.ValueType.STRING, slist);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
}

}

