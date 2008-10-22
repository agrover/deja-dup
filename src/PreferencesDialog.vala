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

public class PreferencesDialog : Gtk.Dialog
{
  static const int FILE_LIST = 0;
  static const int S3_LIST = 1;
  static const int NUM_LISTS = 2;
  List<Gtk.Widget>[] backend_widgets;
  
  Gtk.SizeGroup label_sizes;
  
  construct {
    set("transient-for", toplevel,
        "title", _("Déjà Dup Preferences"),
        "has-separator", false);
    add_buttons(Gtk.STOCK_CLOSE, Gtk.ResponseType.CLOSE);
    
    var table = new Gtk.Table(0, 3, false);
    table.set("border-width", 3);
    int row = 0;
    
    Gtk.Widget w;
    Gtk.Label label;
    
    backend_widgets = new List<Gtk.Widget>[NUM_LISTS];
    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    
    ConfigBackend backend = new ConfigBackend(BACKEND_KEY);
    backend.changed += handle_backend_changed;
    label = new Gtk.Label(_("_Backup location:"));
    label.set("mnemonic-widget", backend,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, 1, row, row + 1,
                 0, Gtk.AttachOptions.FILL, 3, 3);
    table.attach(backend, 1, 2, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 3, 3);
    
    w = new Gtk.Image.from_stock(Gtk.STOCK_HELP, Gtk.IconSize.BUTTON);
    var button = new Gtk.Button();
    button.clicked += handle_link_clicked;
    button.add(w);
    table.attach(button, 2, 3, row, row + 1,
                 Gtk.AttachOptions.FILL,
                 Gtk.AttachOptions.FILL, 3, 3);
    backend_widgets[S3_LIST].append(button);
    ++row;
    
    var s3_table = new Gtk.Table(1, 3, false);
    w = new ConfigEntry(S3_BUCKET_KEY);
    label = new Gtk.Label("    %s".printf(_("S3 buc_ket:")));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    s3_table.attach(label, 0, 1, 0, 1,
                    0, Gtk.AttachOptions.FILL, 3, 3);
    s3_table.attach(w, 1, 3, 0, 1,
                    Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                    Gtk.AttachOptions.FILL, 3, 3);
    
    w = new ConfigEntry(S3_ID_KEY);
    label = new Gtk.Label("    %s".printf(_("S3 I_D:")));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    s3_table.attach(label, 0, 1, 1, 2,
                    0, Gtk.AttachOptions.FILL, 3, 3);
    s3_table.attach(w, 1, 3, 1, 2,
                    Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                    Gtk.AttachOptions.FILL, 3, 3);
    
    table.attach(s3_table, 0, 3, row, row + 1,
                 Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL,
                 0, 0);
    backend_widgets[S3_LIST].append(s3_table);
    ++row;
    
    var file_table = new Gtk.Table(1, 3, false);
    w = new ConfigFolder(FILE_PATH_KEY);
    label = new Gtk.Label("    %s".printf(_("_Folder:")));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    file_table.attach(label, 0, 1, 0, 1,
                      0, Gtk.AttachOptions.FILL, 3, 3);
    file_table.attach(w, 1, 3, 0, 1,
                      Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                      Gtk.AttachOptions.FILL, 3, 3);
    table.attach(file_table, 0, 3, row, row + 1,
                 Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL,
                 0, 0);
    backend_widgets[FILE_LIST].append(file_table);
    ++row;
    
    w = new ConfigList(INCLUDE_LIST_KEY);
    label = new Gtk.Label(_("I_nclude:"));
    label.set("use-underline", true,
              "xalign", 0.0f,
              "yalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, 1, row, row + 1,
                 0, Gtk.AttachOptions.FILL, 3, 3);
    table.attach(w, 1, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 3, 3);
    ++row;
    
    w = new ConfigList(EXCLUDE_LIST_KEY);
    label = new Gtk.Label(_("E_xclude:"));
    label.set("use-underline", true,
              "xalign", 0.0f,
              "yalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, 1, row, row + 1,
                 0, Gtk.AttachOptions.FILL, 3, 3);
    table.attach(w, 1, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 3, 3);
    ++row;
    
    w = new ConfigBool(ENCRYPT_KEY, _("_Encrypt backup files"));
    table.attach(w, 0, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 3, 3);
    ++row;
    
    handle_backend_changed(backend, backend.get_current_value());
    vbox.add(table);
  }
  
  void handle_backend_changed(ConfigBackend backend, string val)
  {
    for (int i = 0; i < NUM_LISTS; ++i) {
      bool show = false;
      if (i == S3_LIST && val == "s3")
        show = true;
      else if (i == FILE_LIST && val == "file")
        show = true;
      
      foreach (Gtk.Widget w in backend_widgets[i]) {
        w.no_show_all = !show;
        if (show)
          w.show_all();
        else
          w.hide();
      }
    }
  }
  
  void handle_link_clicked(Gtk.Button button)
  {
    show_uri((Gtk.Window)button.get_toplevel(), "http://aws.amazon.com/s3/");
  }
}

