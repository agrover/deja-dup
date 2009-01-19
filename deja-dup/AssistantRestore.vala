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
  
  DejaDup.OperationStatus query_op;
  Gtk.ProgressBar query_progress_bar;
  uint query_timeout_id;
  Gtk.ComboBox date_combo;
  Gtk.ListStore date_store;
  Gtk.HBox cust_box;
  Gtk.FileChooserButton cust_button;
  Gtk.Table confirm_table;
  Gtk.Label confirm_backup;
  Gtk.Label confirm_location;
  int confirm_date_row;
  Gtk.Label confirm_date_label;
  Gtk.Label confirm_date;
  Gtk.Widget query_progress_page;
  Gtk.Widget date_page;
  bool got_dates;
  construct
  {
    title = _("Restore");
    
    set_forward_page_func(do_forward);
  }
  
  protected override void add_setup_pages()
  {
    add_query_backend_page();
    add_date_page();
    add_restore_dest_page();
  }
  
  Gtk.Widget make_query_backend_page()
  {
    query_progress_bar = new Gtk.ProgressBar();
    
    var page = new Gtk.VBox(false, 6);
    page.set("child", query_progress_bar,
             "border-width", 12);
    page.child_set(query_progress_bar, "expand", false);
    
    return page;
  }
  
  Gtk.Widget make_date_page()
  {
    date_store = new Gtk.ListStore(2, typeof(string), typeof(string));
    date_combo = new Gtk.ComboBox.text();
    date_combo.model = date_store;
    
    var date_label = new Gtk.Label(_("_Date:"));
    date_label.set("mnemonic-widget", date_combo,
                   "use-underline", true,
                   "xalign", 0.0f);
    
    var hbox = new Gtk.HBox(false, 6);
    hbox.set("child", date_label,
             "child", date_combo);
    
    var page = new Gtk.VBox(false, 6);
    page.set("child", hbox,
             "border-width", 12);
    
    hbox.child_set(date_label, "expand", false);
    hbox.child_set(date_combo, "expand", false);
    page.child_set(hbox, "expand", false);
    
    return page;
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
    
    confirm_date_label = new Gtk.Label(_("Restore date:"));
    confirm_date_label.set("xalign", 0.0f);
    confirm_date = new Gtk.Label("");
    confirm_date.set("xalign", 0.0f);
    ++rows;
    
    var location_label = new Gtk.Label(_("Restore folder:"));
    location_label.set("xalign", 0.0f);
    confirm_location = new Gtk.Label("");
    confirm_location.set("xalign", 0.0f);
    ++rows;
    
    confirm_table = new Gtk.Table(rows, 3, false);
    var page = confirm_table;
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    
    rows = 0;
    page.attach(backup_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(confirm_backup, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    confirm_date_row = rows;
    page.attach(confirm_date_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(confirm_date, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    page.attach(location_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(confirm_location, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    
    return page;
  }
  
  void add_query_backend_page()
  {
    var page = make_query_backend_page();
    append_page(page);
    child_set(page,
              "title", _("Checking for Backups"),
              "complete", false,
              "header-image", icon);
    query_progress_page = page;
  }
  
  void add_date_page()
  {
    var page = make_date_page();
    append_page(page);
    child_set(page,
              "title", _("Restore from When?"),
              "complete", true,
              "header-image", icon);
    date_page = page;
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
    string date = null;
    if (got_dates) {
      Gtk.TreeIter iter;
      if (date_combo.get_active_iter(out iter))
        date_store.get(iter, 1, out date);
    }
    
    return new DejaDup.OperationRestore(this, restore_location, date);
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
  
  protected void handle_collection_dates(DejaDup.OperationStatus op, List<string>? dates)
  {
    TimeVal tv = TimeVal();
    
    got_dates = true;
    date_store.clear();
    
    foreach (string date in dates) {
      if (tv.from_iso8601(date)) {
        Time t = Time.local(tv.tv_sec);
        string user_str = t.format("%c");
        Gtk.TreeIter iter;
        date_store.prepend(out iter);
        date_store.@set(iter, 0, user_str, 1, date);
        date_combo.set_active_iter(iter);
      }
    }
    
    // If we didn't see any dates...  Must not be any backups on the backend
    if (date_store.iter_n_children(null) == 0)
      show_error(query_op, _("No backups to restore"), null);
  }
  
  protected void query_finished(DejaDup.OperationStatus op, bool success)
  {
    if (success) {
      set_current_page(do_forward(get_current_page())); // next page
    }
    
    this.query_op = null;
  }
  
  bool query_pulse()
  {
    query_progress_bar.pulse();
    return true;
  }
  
  protected void do_query()
  {
    query_op = new DejaDup.OperationStatus(this);
    query_op.collection_dates += handle_collection_dates;
    query_op.done += query_finished;
    ((DejaDup.Operation)query_op).raise_error += show_error;
    
    try {
      query_op.start();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      show_error(query_op, e.message, null); // not really user-friendly text, but ideally this won't happen
      query_finished(query_op, false);
    }
  }
  
  protected int do_forward(int n)
  {
    if (n >= get_n_pages() - 1)
      return -1;
    
    int next = n + 1;
    Gtk.Widget next_page = get_nth_page(next);
    
    if (next_page == date_page) {
      if (!got_dates) {
        // Hmm, we never got a date from querying the backend, but we also
        // didn't hit an error (since we're about to show this page, and not
        // the summary/error page).  Skip the date portion, since the backend
        // must not be capable of giving us dates (duplicity < 0.5.04 couldn't).
        ++next;
      }
    }
    
    return next;
  }
  
  protected override void do_prepare(AssistantOperation assist, Gtk.Widget page)
  {
    base.do_prepare(assist, page);
    
    if (query_timeout_id > 0) {
      Source.remove(query_timeout_id);
      query_timeout_id = 0;
    }
    
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
      
      // When we restore from
      if (got_dates) {
        confirm_date.label = date_combo.get_active_text();
        confirm_date_label.show();
        confirm_date.show();
        confirm_table.set_row_spacing(confirm_date_row,
                                      confirm_table.get_default_row_spacing());
      }
      else {
        confirm_date_label.hide();
        confirm_date.hide();
        confirm_table.set_row_spacing(confirm_date_row, 0);
      }
      
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
    else if (page == query_progress_page) {
      query_progress_bar.fraction = 0;
      query_timeout_id = Timeout.add(250, query_pulse);
      do_query();
    }
  }
  
  protected override void do_close()
  {
    if (query_timeout_id > 0) {
      Source.remove(query_timeout_id);
      query_timeout_id = 0;
    }
    
    base.do_close();
  }
}

