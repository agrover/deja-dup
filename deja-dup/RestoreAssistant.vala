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
  Gtk.Label confirm_backup;
  Gtk.Label confirm_location;
  Gtk.Widget confirm_page;
  Gtk.Label progress_label;
  Gtk.Label progress_file_label;
  Gtk.ProgressBar progress_bar;
  Gtk.Widget progress_page;
  Gtk.Label summary_label;
  Gtk.Widget error_widget;
  Gtk.TextView error_text_view;
  Gtk.Widget summary_page;
  Gdk.Pixbuf icon;
  DejaDup.OperationRestore op;
  uint timeout_id;
  bool error_occurred;
  bool gives_progress;
  construct
  {
    title = _("Restore");
    
    try {
      var filename = get_restore_icon_filename();
      icon = new Gdk.Pixbuf.from_file_at_size(filename, 48, 48);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    add_restore_dest_page();
    add_confirm_page();
    add_progress_page();
    add_summary_page();
    
    apply += do_apply;
    cancel += do_cancel;
    close += do_close;
    prepare += do_prepare;
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
  
  Gtk.Widget make_confirm_page()
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
  
  bool pulse()
  {
    if (!gives_progress)
      progress_bar.pulse();
    return true;
  }
  
  void show_progress(DejaDup.OperationRestore restore, double percent)
  {
    progress_bar.fraction = percent;
    gives_progress = true;
  }
  
  void set_progress_label(DejaDup.OperationRestore restore, string label)
  {
    progress_label.label = label;
  }
  
  void set_progress_label_file(DejaDup.OperationRestore restore, File file)
  {
    var parse_name = file.get_parse_name();
    var basename = Path.get_basename(parse_name);
    progress_label.label = _("Restoring") + " ";
    progress_file_label.label = "'%s'".printf(basename);
  }
  
  Gtk.Widget make_progress_page()
  {
    progress_label = new Gtk.Label("");
    progress_label.set("xalign", 0.0f);
    
    progress_file_label = new Gtk.Label("");
    progress_file_label.set("xalign", 0.0f,
                            "ellipsize", Pango.EllipsizeMode.MIDDLE);
    
    var progress_hbox = new Gtk.HBox(false, 0);
    progress_hbox.set("child", progress_label,
                      "child", progress_file_label);
    progress_hbox.child_set(progress_label, "expand", false);
    
    progress_bar = new Gtk.ProgressBar();
    
    var page = new Gtk.VBox(false, 6);
    page.set("child", progress_hbox,
             "child", progress_bar,
             "border-width", 12);
    page.child_set(progress_hbox, "expand", false);
    page.child_set(progress_bar, "expand", false);
    
    return page;
  }
  
  void show_error(DejaDup.OperationRestore restore, string error, string? detail)
  {
    error_occurred = true;
    
    child_set(summary_page,
              "title", _("Restore Failed"));
    
    // Try to show nice error icon
    try {
      var pixbuf = Gtk.IconTheme.get_default().load_icon(
                     Gtk.STOCK_DIALOG_ERROR, 48, 
                     Gtk.IconLookupFlags.FORCE_SIZE);
      child_set(summary_page,
                "header-image", pixbuf);
    }
    catch (Error e) {
      // Eh, don't worry about it
    }
    
    summary_label.label = error;
    summary_label.wrap = true;
    summary_label.selectable = true;
    
    if (detail != null) {
      error_widget.no_show_all = false;
      error_widget.show_all();
      error_text_view.buffer.set_text(detail, -1);
    }
    
    set_current_page(get_n_pages() - 1); // last, summary page
  }
  
  Gtk.Widget make_summary_page()
  {
    summary_label = new Gtk.Label("");
    summary_label.set("xalign", 0.0f);
    
    error_text_view = new Gtk.TextView();
    error_text_view.editable = false;
    error_text_view.wrap_mode = Gtk.WrapMode.WORD;
    error_text_view.height_request = 150;

    var scroll = new Gtk.ScrolledWindow(null, null);
    scroll.add(error_text_view);
    scroll.no_show_all = true; // only will be shown if an error occurs
    error_widget = scroll;
    
    var page = new Gtk.VBox(false, 6);
    page.set("child", summary_label,
             "child", error_widget,
             "border-width", 12);
    page.child_set(summary_label, "expand", false);
    
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
  
  void add_confirm_page()
  {
    var page = make_confirm_page();
    append_page(page);
    child_set(page,
              "title", _("Summary"),
              "page-type", Gtk.AssistantPageType.CONFIRM,
              "complete", true,
              "header-image", icon);
    confirm_page = page;
  }

  void add_progress_page()
  {
    var page = make_progress_page();
    append_page(page);
    // We don't actually use a PROGRESS type for this page, because that
    // doesn't allow for cancelling.
    child_set(page,
              "title", _("Restoring"),
              "page-type", Gtk.AssistantPageType.CONTENT,
              "header-image", icon);
    progress_page = page;
  }
  
  void add_summary_page()
  {
    var page = make_summary_page();
    append_page(page);
    child_set(page,
              "title", _("Restore Finished"),
              "page-type", Gtk.AssistantPageType.SUMMARY,
              "complete", true,
              "header-image", icon);
    summary_page = page;
  }
  
  void apply_finished(DejaDup.OperationRestore restore, bool success)
  {
    op = null;
    
    if (success) {
      summary_label.label = _("Your files were successfully restored.");
      set_current_page(get_n_pages() - 1); // last, summary page
    }
    else if (!error_occurred) {
      // was cancelled...  Close dialog
      do_cancel();
    }
  }
  
  void do_apply()
  {
    op = new DejaDup.OperationRestore(this, restore_location);
    op.done += apply_finished;
    op.raise_error += show_error;
    op.action_desc_changed += set_progress_label;
    op.action_file_changed += set_progress_label_file;
    op.progress += show_progress;
    
    try {
      op.start();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      show_error(op, e.message, null); // not really user-friendly text, but ideally this won't happen
      apply_finished(op, false);
    }
  }
  
  void do_prepare(RestoreAssistant assist, Gtk.Widget page)
  {
    if (timeout_id > 0) {
      Source.remove(timeout_id);
      timeout_id = 0;
    }
    
    if (page == confirm_page) {
      if (op != null) {
        op.done -= apply_finished;
        op.cancel(); // in case we just went back from progress page
      }
      
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
    else if (page == progress_page) {
      progress_bar.fraction = 0;
      timeout_id = Timeout.add(250, pulse);
    }
  }
  
  void do_cancel()
  {
    if (op != null)
      op.cancel();
    do_close();
  }
  
  void do_close()
  {
    if (timeout_id > 0) {
      Source.remove(timeout_id);
      timeout_id = 0;
    }
    
    destroy();
  }
}

