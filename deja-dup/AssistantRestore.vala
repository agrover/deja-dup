/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
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

public class AssistantRestore : AssistantOperation
{
  public string restore_location {get; protected set; default = "/";}
  
  Gtk.HBox cust_box;
  Gtk.FileChooserButton cust_button;
  Gtk.Label confirm_backup;
  Gtk.Label confirm_location;
  construct
  {
    title = _("Restore");
  }
  
  protected override void add_setup_pages()
  {
    add_restore_dest_page();
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
    cust_button.file_set += (b) => {restore_location = b.get_filename();};
    cust_button.current_folder_changed += (b) => {restore_location = b.get_filename();};
    
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
  
  protected override Gtk.Widget make_confirm_page()
  {
    int rows = 0;
    
    var backup_label = new Gtk.Label(_("Backup location:"));
    backup_label.set("xalign", 0.0f);
    confirm_backup = new Gtk.Label("");
    confirm_backup.set("xalign", 0.0f);
    ++rows;
    
    var location_label = new Gtk.Label(_("Restore folder:"));
    location_label.set("xalign", 0.0f);
    confirm_location = new Gtk.Label("");
    confirm_location.set("xalign", 0.0f);
    ++rows;
    
    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    
    rows = 0;
    page.attach(backup_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(confirm_backup, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    page.attach(location_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(confirm_location, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    
    return page;
  }
  
  void add_restore_dest_page()
  {
    var page = make_restore_dest_page();
    append_page(page);
    child_set(page,
              "title", _("Restore to Where?"),
              "complete", true,
              "header-image", icon);
  }
  
  protected override DejaDup.Operation create_op()
  {
    return new DejaDup.OperationRestore(this, restore_location);
  }
  
  protected override string get_progress_file_prefix()
  {
    // Translators:  This is the word 'Restoring' in the phrase
    // "Restoring '%s'".  %s is a filename.
    return _("Restoring");
  }
  
  protected override Gdk.Pixbuf? get_op_icon()
  {
    try {
      var filename = get_restore_icon_filename();
      return new Gdk.Pixbuf.from_file_at_size(filename, 48, 48);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return null;
    }
  }
  
  protected override void do_prepare(AssistantOperation assist, Gtk.Widget page)
  {
    base.do_prepare(assist, page);
    
    if (page == confirm_page) {
      // Where the backup is
      string backup_loc = null;
      try {
        backup_loc = DejaDup.Backend.get_default(this).get_location_pretty();
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
      if (backup_loc == null)
        backup_loc = _("Unknown");
      confirm_backup.label = backup_loc;
      
      // Where we restore to
      if (restore_location == "/")
        confirm_location.label = _("Original location");
      else
        confirm_location.label = restore_location;
    }
    else if (page == summary_page) {
      if (error_occurred)
        assist.child_set(page, "title", _("Restore Failed"));
      else {
        assist.child_set(page, "title", _("Restore Finished"));
        summary_label.label = _("Your files were successfully restored.");
      }
    }
    else if (page == progress_page) {
      assist.child_set(page, "title", _("Restoring..."));
    }
  }
}

