/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
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
  
  private List<File> _restore_files;
  public List<File> restore_files {
    get {
      return this._restore_files;
    }
    set {
      foreach (File f in this._restore_files)
        f.unref();
      this._restore_files = value.copy();
      foreach (File f in this._restore_files)
        f.ref();
    }
  }
  
  public AssistantRestore.with_files(List<File> files)
  {
    // This puts the restore dialog into 'known file mode', where it only
    // restores the listed files, not the whole backup
    restore_files = files;
  }
  
  DejaDup.OperationStatus query_op;
  Gtk.ProgressBar query_progress_bar;
  uint query_timeout_id;
  Gtk.ComboBox date_combo;
  Gtk.ListStore date_store;
  Gtk.HBox cust_box;
  Gtk.FileChooserButton cust_button;
  Gtk.Table confirm_table;
  Gtk.Widget confirm_backup;
  int confirm_location_row;
  Gtk.Label confirm_location_label;
  Gtk.Label confirm_location;
  int confirm_date_row;
  Gtk.Label confirm_date_label;
  Gtk.Label confirm_date;
  int confirm_files_row;
  Gtk.Label confirm_files_label;
  Gtk.VBox confirm_files;
  Gtk.Widget query_progress_page;
  Gtk.Widget date_page;
  Gtk.Widget restore_dest_page;
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
  
  Gtk.Widget make_backup_location_page()
  {
    int rows = 0;
    Gtk.Widget w, label;
    
    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    
    w = new DejaDup.ConfigLocation();
    label = new Gtk.Label.with_mnemonic(_("_Backup location:"));
    label.set("xalign", 0.0f,
              "mnemonic-widget", w);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(w, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, 0, 0, 0);
    ++rows;
    
    w = new DejaDup.ConfigBool(DejaDup.ENCRYPT_KEY, _("Backup files are _encrypted"));
    page.attach(w, 0, 2, rows, rows + 1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                Gtk.AttachOptions.FILL, 0, 0);
    ++rows;
    
    return page;
  }
  
  protected override void add_custom_config_pages()
  {
    var page = make_backup_location_page();
    append_page(page);
    child_set(page,
              "title", _("Preferences"),
              "page-type", Gtk.AssistantPageType.CONTENT,
              "complete", true,
              "header-image", op_icon);
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
    orig_radio.toggled.connect((r) => {if (r.active) restore_location = "/";});
    
    var cust_radio = new Gtk.RadioButton(null);
    cust_radio.set("label", _("Restore to _specific folder"),
                   "use-underline", true,
                   "group", orig_radio);
    cust_radio.toggled.connect((r) => {
      if (r.active)
        restore_location = cust_button.get_filename();
      cust_box.sensitive = r.active;
    });
    
    cust_button =
      new Gtk.FileChooserButton(_("Choose destination for restored files"),
                                Gtk.FileChooserAction.SELECT_FOLDER);
    cust_button.selection_changed.connect((b) => {restore_location = b.get_filename();});
    
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
    
    confirm_backup = new DejaDup.ConfigLocation();
    var backup_label = new Gtk.Label.with_mnemonic(_("_Backup location:"));
    backup_label.set("xalign", 0.0f,
                     "mnemonic-widget", confirm_backup);
    ++rows;
    
    confirm_date_label = new Gtk.Label(_("Restore date:"));
    confirm_date_label.set("xalign", 0.0f);
    confirm_date = new Gtk.Label("");
    confirm_date.set("xalign", 0.0f);
    ++rows;
    
    confirm_location_label = new Gtk.Label(_("Restore folder:"));
    confirm_location_label.set("xalign", 0.0f);
    confirm_location = new Gtk.Label("");
    confirm_location.set("xalign", 0.0f);
    ++rows;
    
    confirm_files_label = new Gtk.Label("");
    confirm_files_label.set("xalign", 0.0f, "yalign", 0.0f);
    confirm_files = new Gtk.VBox(true, 6);
    ++rows;
    
    confirm_table = new Gtk.Table(rows, 3, false);
    var page = confirm_table;
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    
    rows = 0;
    page.attach(backup_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    page.attach(confirm_backup, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, 0, 0, 0);
    ++rows;
    confirm_date_row = rows;
    page.attach(confirm_date_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    page.attach(confirm_date, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    confirm_location_row = rows;
    page.attach(confirm_location_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    page.attach(confirm_location, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    confirm_files_row = rows;
    page.attach(confirm_files_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    page.attach(confirm_files, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    
    return page;
  }
  
  void add_query_backend_page()
  {
    var page = make_query_backend_page();
    append_page(page);
    child_set(page,
              "title", _("Checking for Backups"),
              "complete", false,
              "header-image", op_icon);
    query_progress_page = page;
  }
  
  void add_date_page()
  {
    var page = make_date_page();
    append_page(page);
    child_set(page,
              "title", _("Restore from When?"),
              "complete", true,
              "header-image", op_icon);
    date_page = page;
  }
  
  void add_restore_dest_page()
  {
    var page = make_restore_dest_page();
    append_page(page);
    child_set(page,
              "title", _("Restore to Where?"),
              "complete", true,
              "header-image", op_icon);
    restore_dest_page = page;
  }
  
  protected override DejaDup.Operation create_op()
  {
    string date = null;
    if (got_dates) {
      Gtk.TreeIter iter;
      if (date_combo.get_active_iter(out iter))
        date_store.get(iter, 1, out date);
    }
    
    return new DejaDup.OperationRestore(this, restore_location, date,
                                        restore_files);
  }
  
  protected override string get_progress_file_prefix()
  {
    // Translators:  This is the word 'Restoring' in the phrase
    // "Restoring '%s'".  %s is a filename.
    return _("Restoring");
  }
  
  protected override Gdk.Pixbuf? make_op_icon()
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
  
  protected void query_finished(DejaDup.Operation op, bool success)
  {
    if (success && !error_occurred) {
      var next_page = do_forward(get_current_page());
      if (next_page >= 0)
        set_current_page(next_page);
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
    query_op.collection_dates.connect(handle_collection_dates);
    query_op.done.connect(query_finished);
    ((DejaDup.Operation)query_op).raise_error.connect(show_error);
    
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
        next_page = get_nth_page(++next);
      }
    }
    
    // If we're doing a known-file-set restore, assume user wants same-location
    // restore.
    if (next_page == restore_dest_page && restore_files != null)
      next_page = get_nth_page(++next);
    
    return next;
  }
  
  protected override void do_prepare(Gtk.Assistant assist, Gtk.Widget page)
  {
    base.do_prepare(assist, page);
    
    if (query_timeout_id > 0) {
      Source.remove(query_timeout_id);
      query_timeout_id = 0;
    }
    
    if (page == confirm_page) {
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
      if (restore_files == null) {
        if (restore_location == "/")
          confirm_location.label = _("Original location");
        else
          confirm_location.label = restore_location;
        
        confirm_location_label.show();
        confirm_location.show();
        confirm_table.set_row_spacing(confirm_location_row,
                                      confirm_table.get_default_row_spacing());
        confirm_files_label.hide();
        confirm_files.hide();
        confirm_table.set_row_spacing(confirm_files_row, 0);
      }
      else {
        confirm_files_label.label = ngettext("File to restore:",
                                             "Files to restore:",
                                             restore_files.length());
        foreach (File f in restore_files) {
          var parse_name = f.get_parse_name();
          var file_label = new Gtk.Label(Path.get_basename(parse_name));
          file_label.set_tooltip_text(parse_name);
          file_label.set("xalign", 0.0f);
          confirm_files.add(file_label);
        }
        
        confirm_location_label.hide();
        confirm_location.hide();
        confirm_table.set_row_spacing(confirm_location_row, 0);
        confirm_files_label.show();
        confirm_files.show_all();
        confirm_table.set_row_spacing(confirm_files_row,
                                      confirm_table.get_default_row_spacing());
      }
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

