/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
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

public class RestoreAssistant : Gtk.Assistant
{
  public string restore_location {get; protected set; default = "/";}
  
  Gtk.HBox cust_box;
  Gtk.FileChooserButton cust_button;
  Gdk.Pixbuf icon;
  construct
  {
    title = _("Restore");
    
    try {
      var filename = get_restore_icon_filename();
      icon = new Gdk.Pixbuf.from_file_at_size(filename, 48, 48);
    }
    catch (Error e) {
      warning("%s", e.message);
    }
    
    add_restore_dest_page();
    add_summary_page();
  }
  
  Gtk.Widget make_restore_dest_page()
  {
    var orig_radio = new Gtk.RadioButton(null);
    orig_radio.set("label", _("Restore files to _original locations"),
                   "use-underline", true);
    orig_radio.toggled += (r) => {if (r.active) restore_location = "/";};
    
    var cust_radio = new Gtk.RadioButton(null);
    cust_radio.set("label", _("Restore to _specific folder"),
                   "use-underline", true,
                   "group", orig_radio);
    cust_radio.toggled += (r) => {
      if (r.active)
        restore_location = cust_button.get_filename();
      cust_box.sensitive = r.active;
    };
    
    cust_button =
      new Gtk.FileChooserButton(_("Choose destination for restored files"),
                                Gtk.FileChooserAction.SELECT_FOLDER);
    
    var cust_label = new Gtk.Label("    " + _("Restore _folder:"));
    cust_label.set("mnemonic-widget", cust_button,
                   "use-underline", true,
                   "xalign", 0.0f);
    
    cust_box = new Gtk.HBox(false, 6);
    cust_box.set("child", cust_label,
                 "child", cust_button,
                 "sensitive", false);
    
    var page = new Gtk.VBox(false, 6);
    page.set("child", orig_radio,
             "child", cust_radio,
             "child", cust_box,
             "border-width", 12);
    page.child_set(orig_radio, "expand", false);
    page.child_set(cust_radio, "expand", false);
    page.child_set(cust_box, "expand", false);
    
    return page;
  }
  
  Gtk.Widget make_summary_page()
  {
    int rows = 0;
    
    var location_label = new Gtk.Label(_("Restore folder:"));
    location_label.set("xalign", 0.0f);
    
    var location = new Gtk.Label(restore_location);
    if (restore_location == "/")
      location.label = _("Original location");
    
    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    page.attach(location_label, 0, 1, 0, 1, 0, 0, 0, 0);
    page.attach(location, 1, 2, 0, 1, 0, 0, 0, 0);
    
    return page;
  }
  
  void add_restore_dest_page()
  {
    var page = make_restore_dest_page();
    append_page(page);
    child_set(page,
              "title", _("Restore to where?"),
              "page-type", Gtk.AssistantPageType.CONTENT,
              "complete", true,
              "header-image", icon);
  }
  
  void add_summary_page()
  {
    var page = make_summary_page();
    append_page(page);
    child_set(page,
              "title", _("Summary"),
              "page-type", Gtk.AssistantPageType.CONFIRM,
              "complete", true,
              "header-image", icon);
  }
}

