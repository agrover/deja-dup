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

// This is a convenience version of Gtk.ListStore that handles the drag and
// drop code.
class ConfigListStore : Gtk.ListStore, Gtk.TreeDragDest, Gtk.TreeDragSource
{
  public ConfigList list {get; construct;}

  public ConfigListStore(ConfigList list)
  {
    Object(list: list);
  }

  construct {
    // path, display name, icon
    GLib.Type[] types = {typeof(string), typeof(string), typeof(Icon)};
    set_column_types(types);
  }

  public bool drag_data_received (Gtk.TreePath dest,
                                  Gtk.SelectionData selection_data)
  {
    if (base.drag_data_received(dest, selection_data))
      return true;

    string[] uris = selection_data.get_uris();
    if (uris == null)
      return false;

    // Only use URIs that are local full paths
    SList<string> files = new SList<string>();
    foreach (weak string uri in uris) {
      if (Uri.parse_scheme(uri) != "file")
        continue;
      try {
        var file = Filename.from_uri(uri, null);
        if (file == null)
          continue;
        var gfile = File.new_for_path(file);
        if (gfile.query_file_type(FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY)
          files.append(file);
      }
      catch (ConvertError e) {
        warning("%s", e.message);
      }
    }

    return list.add_files(files);
  }

  public bool drag_data_get (Gtk.TreePath path,
                             Gtk.SelectionData selection_data)
  {
    if (base.drag_data_get(path, selection_data))
      return true;

    Gtk.TreeIter iter;
    if (!get_iter(out iter, path))
      return false;

    string file;
    get(iter, 0, out file);

    string uri;
    try {
      uri = Filename.to_uri(file, null);
    }
    catch (ConvertError e) {
      warning("%s", e.message);
      return false;
    }

    string[] uris = {uri};
    return selection_data.set_uris(uris);
  }
}

public class ConfigList : ConfigWidget
{
  public ConfigList(string key, string ns="")
  {
    Object(key: key, ns: ns);
  }

  // Assumes key is simple ascii
  static string convert_key_to_a11y_name(string key)
  {
    var name = new StringBuilder();
    var next_upper = true;
    int i = 0;
    unichar ch;
    while ((ch = key.get_char(i++)) != 0) {
      if (ch == '-') {
        next_upper = true;
        continue;
      }
      if (next_upper) {
        ch = ch.toupper();
        next_upper = false;
      }
      name.append_unichar(ch);
    }
    return name.str;
  }

  Gtk.TreeView tree;
  Gtk.ToolButton add_button;
  Gtk.ToolButton remove_button;
  construct {
    var model = new ConfigListStore(this);
    tree = new Gtk.TreeView();
    tree.model = model;
    tree.headers_visible = false;
    mnemonic_widget = tree;

    var a11y_name = convert_key_to_a11y_name(key);

    var accessible = tree.get_accessible();
    if (accessible != null)
      accessible.set_name(a11y_name);

    tree.insert_column_with_attributes(-1, null, new Gtk.CellRendererPixbuf(),
                                       "gicon", 2);
    
    var renderer = new Gtk.CellRendererText();
    tree.insert_column_with_attributes(-1, null, renderer,
                                       "text", 1);

    Gtk.TargetEntry[] targets = new Gtk.TargetEntry[1];
    targets[0].target = "text/uri-list";
    targets[0].flags = Gtk.TargetFlags.OTHER_WIDGET;
    targets[0].info = Quark.from_string(key);
    tree.enable_model_drag_dest (targets, Gdk.DragAction.COPY);

    // Allow moving within our own app
    targets[0].flags = Gtk.TargetFlags.SAME_APP;
    tree.enable_model_drag_source (Gdk.ModifierType.BUTTON1_MASK, targets,
                                   Gdk.DragAction.MOVE);

    // For when the above drag moves files away
    model.row_deleted.connect(write_to_config);

    var scroll = new Gtk.ScrolledWindow(null, null);
    scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
    scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
    scroll.shadow_type = Gtk.ShadowType.IN;
    scroll.add(tree);

    var tbar = new Gtk.Toolbar();
    tbar.set_style(Gtk.ToolbarStyle.ICONS);
    tbar.set_icon_size(Gtk.IconSize.SMALL_TOOLBAR);
    tbar.set_show_arrow(false);

    scroll.get_style_context().set_junction_sides(Gtk.JunctionSides.BOTTOM);
    tbar.get_style_context().add_class(Gtk.STYLE_CLASS_INLINE_TOOLBAR);
    tbar.get_style_context().set_junction_sides(Gtk.JunctionSides.TOP);

    add_button = new Gtk.ToolButton(null, _("_Add"));
    add_button.set_tooltip_text(_("Add"));
    add_button.set_icon_name("list-add-symbolic");
    add_button.clicked.connect(handle_add);
    accessible = add_button.get_accessible();
    if (accessible != null)
      accessible.set_name(a11y_name + "Add");
    tbar.insert(add_button, -1);

    remove_button = new Gtk.ToolButton(null, _("_Remove"));
    remove_button.set_tooltip_text(_("Remove"));
    remove_button.set_icon_name("list-remove-symbolic");
    remove_button.clicked.connect(handle_remove);
    accessible = remove_button.get_accessible();
    if (accessible != null)
      accessible.set_name(a11y_name + "Remove");
    tbar.insert(remove_button, -1);

    var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

    vbox.pack_start(scroll, true, true, 0);
    vbox.pack_start(tbar, false, true, 0);
    add(vbox);
    
    var selection = tree.get_selection();
    selection.set_mode(Gtk.SelectionMode.MULTIPLE);
    
    key_press_event.connect(on_key_press_event);
    
    set_from_config.begin();
    handle_selection_change(selection);
    selection.changed.connect(handle_selection_change);
  }
  
  bool on_key_press_event(Gtk.Widget w, Gdk.EventKey e)
  {
    uint modifiers = Gtk.accelerator_get_default_mod_mask();
    
    // Vala keysym bindings would be nice.  Check for delete or kp_delete
    if ((e.keyval == 0xffff || e.keyval == 0xff9f) && (e.state & modifiers) == 0) {
      handle_remove();
      return true;
    }
    else
      return false;
  }

  protected override async void set_from_config()
  {
    var slist_val = settings.get_value(key);
    string*[] slist = slist_val.get_strv();
    
    var list = DejaDup.parse_dir_list(slist);
    
    Gtk.ListStore model;
    tree.get("model", out model);
    model.row_deleted.disconnect(write_to_config);
    model.clear();
    model.row_deleted.connect(write_to_config);
    
    int i = 0;
    var trash = File.new_for_path(DejaDup.get_trash_path());
    foreach (File f in list) {
      string s = yield DejaDup.get_nickname(f);

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
          FileInfo info = f.query_info(FileAttribute.STANDARD_ICON, FileQueryInfoFlags.NONE, null);
          icon = info.get_icon();
        }
        catch (Error err) {warning("%s\n", err.message);}
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
                                        get_ancestor(typeof(Gtk.Window)) as Gtk.Window,
                                        Gtk.FileChooserAction.SELECT_FOLDER,
                                        Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                          				      Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
    dlg.select_multiple = true;
    
    if (dlg.run() != Gtk.ResponseType.ACCEPT) {
      destroy_widget(dlg);
      return;
    }
    
    SList<string> files = dlg.get_filenames();
    destroy_widget(dlg);

    add_files(files);
  }

  public bool add_files(SList<string>? files)
  {
    if (files == null)
      return false;

    var slist_val = settings.get_value(key);
    string*[] slist = slist_val.get_strv();
    bool rv = false;
    
    foreach (string file in files) {
      var folder = File.new_for_path(file);
      bool found = false;
      foreach (string s in slist) {
        var sfile = DejaDup.parse_dir(s);
        if (sfile != null && sfile.equal(folder)) {
          found = true;
          break;
        }
      }
      
      if (!found) {
        slist += folder.get_parse_name();
        rv = true;
      }
    }

    if (rv) {
      settings.set_value(key, new Variant.strv(slist));
    }
    return rv;
  }

  public string[] get_files()
  {
    var slist_val = settings.get_value(key);
    return slist_val.dup_strv();
  }

  public void write_to_config(Gtk.TreeModel model, Gtk.TreePath? path)
  {
    Gtk.TreeIter iter;
    string[] paths = new string[0];

    if (model.get_iter_first(out iter)) {
      do {
        string current;
        model.get(iter, 0, out current);
        paths += current;
      } while (model.iter_next(ref iter));
    }

    settings.set_value(key, new Variant.strv((string*[])paths));
  }

  void handle_remove()
  {
    var sel = tree.get_selection();

    weak Gtk.TreeModel model;
    List<Gtk.TreePath> paths = sel.get_selected_rows(out model);
    List<Gtk.TreeIter?> iters = null;

    foreach (Gtk.TreePath path in paths) {
      Gtk.TreeIter iter;
      if (model.get_iter(out iter, path))
        iters.prepend(iter);
    }

    model.row_deleted.disconnect(write_to_config);
    foreach (Gtk.TreeIter iter in iters) {
      (model as Gtk.ListStore).remove(iter);
    }
    model.row_deleted.connect(write_to_config);

    write_to_config(model, null);
  }
}

}

