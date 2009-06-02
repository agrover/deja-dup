/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008,2009 Michael Terry <mike@mterry.name>

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
  static const int S3_LIST = 0;
  static const int NUM_LISTS = 1;
  List<Gtk.Widget>[] backend_widgets;
  
  Gtk.SizeGroup label_sizes;
  DejaDup.ToggleGroup periodic_toggle;
  
  public PreferencesDialog(Gtk.Window? parent = null) {
    transient_for = parent;
  }
  
  construct {
    set("title", _("Déjà Dup Preferences"),
        "has-separator", false);
    add_buttons(Gtk.STOCK_CLOSE, Gtk.ResponseType.CLOSE,
                Gtk.STOCK_HELP, Gtk.ResponseType.HELP);
    response.connect(handle_response);
    
    var table = new Gtk.Table(0, 3, false);
    table.set("border-width", 3);
    int row = 0;
    
    Gtk.Widget w;
    Gtk.Label label;
    
    backend_widgets = new List<Gtk.Widget>[NUM_LISTS];
    label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    
    var location = new DejaDup.ConfigLocation();
    location.changed.connect(handle_location_changed);
    label = new Gtk.Label(_("_Backup location:"));
    label.set("mnemonic-widget", location,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, 1, row, row + 1,
                 0, Gtk.AttachOptions.FILL, 3, 3);
    table.attach(location, 1, 2, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 3, 3);
    ++row;
    
    var s3_table = new Gtk.Table(1, 3, false);
    w = new DejaDup.ConfigEntry(DejaDup.S3_ID_KEY);
    label = new Gtk.Label("    %s".printf(_("S3 Access Key I_D:")));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    s3_table.attach(label, 0, 1, 0, 1,
                    0, Gtk.AttachOptions.FILL, 3, 3);
    s3_table.attach(w, 1, 3, 0, 1,
                    Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                    Gtk.AttachOptions.FILL, 3, 3);
    
    w = new DejaDup.ConfigEntry(DejaDup.S3_FOLDER_KEY);
    label = new Gtk.Label("    %s".printf(_("_Folder:")));
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
    
    w = new DejaDup.ConfigList(DejaDup.INCLUDE_LIST_KEY);
    w.set_size_request(250, 80);
    label = new Gtk.Label(_("I_nclude files in folders:"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "wrap", true,
              "width-request", 150,
              "xalign", 0.0f,
              "yalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, 1, row, row + 1,
                 Gtk.AttachOptions.FILL,
                 Gtk.AttachOptions.FILL, 3, 3);
    table.attach(w, 1, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 3, 3);
    ++row;
    
    w = new DejaDup.ConfigList(DejaDup.EXCLUDE_LIST_KEY);
    w.set_size_request(250, 120);
    label = new Gtk.Label(_("E_xcept files in folders:"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "wrap", true,
              "width-request", 150,
              "xalign", 0.0f,
              "yalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, 1, row, row + 1,
                 Gtk.AttachOptions.FILL,
                 Gtk.AttachOptions.FILL, 3, 3);
    table.attach(w, 1, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 3, 3);
    ++row;
    
    w = new DejaDup.ConfigBool(DejaDup.ENCRYPT_KEY, _("_Encrypt backup files"));
    table.attach(w, 0, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 3, 3);
    ++row;
    
    DejaDup.ConfigBool periodic_check = new DejaDup.ConfigBool(DejaDup.PERIODIC_KEY, _("_Automatically backup on a regular schedule"));
    table.attach(periodic_check, 0, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL, 3, 3);
    ++row;
    
    w = new DejaDup.ConfigPeriod(DejaDup.PERIODIC_PERIOD_KEY);
    label = new Gtk.Label("    %s".printf(_("How _often to backup:")));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    label_sizes.add_widget(label);
    table.attach(label, 0, 1, row, row + 1,
                 0, Gtk.AttachOptions.FILL, 3, 3);
    table.attach(w, 1, 3, row, row + 1,
                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                 Gtk.AttachOptions.FILL,
                 3, 3);
    periodic_toggle = new DejaDup.ToggleGroup(periodic_check);
    periodic_toggle.add_dependent(label);
    periodic_toggle.add_dependent(w);
    periodic_toggle.check();
    ++row;
    
    handle_location_changed(location);
    vbox.add(table);
  }
  
  void handle_location_changed(DejaDup.ConfigLocation location)
  {
    for (int i = 0; i < NUM_LISTS; ++i) {
      bool show = false;
      if (i == S3_LIST && location.is_s3)
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
  
  void handle_response(Gtk.Dialog dlg, int response) {
    switch (response) {
    case Gtk.ResponseType.HELP:
      DejaDup.show_uri(dlg, "ghelp:deja-dup#deja-dup-prefs");
      break;
    default:
      Gtk.main_quit();
      break;
    }
  }
}

