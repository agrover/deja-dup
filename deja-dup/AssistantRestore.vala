/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008,2009,2010,2011 Michael Terry <mike@mterry.name>
    © 2010 Andrew Fister <temposs@gmail.com>

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

public class AssistantRestore : AssistantOperation
{
  public string restore_location {get; protected set; default = "/";}
  
  protected List<File> _restore_files;
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
  
  protected DejaDup.OperationStatus query_op;
  protected DejaDup.Operation.State op_state;
  Gtk.ProgressBar query_progress_bar;
  uint query_timeout_id;
  Gtk.ComboBoxText date_combo;
  Gtk.ListStore date_store;
  Gtk.Box cust_box;
  Gtk.FileChooserButton cust_button;
  Gtk.Table confirm_table;
  int confirm_location_row;
  Gtk.Label confirm_location_label;
  Gtk.Label confirm_location;
  int confirm_date_row;
  Gtk.Label confirm_date_label;
  Gtk.Label confirm_date;
  int confirm_files_row;
  Gtk.Label confirm_files_label;
  Gtk.Box confirm_files;
  Gtk.Widget query_progress_page;
  Gtk.Widget date_page;
  Gtk.Widget restore_dest_page;
  bool got_dates;
  construct
  {
    title = _("Restore");
    apply_text = _("_Restore");
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
    Gtk.SizeGroup label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    
    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    
    var location = new DejaDup.ConfigLocation(label_sizes);
    label = new Gtk.Label.with_mnemonic(_("_Backup location:"));
    label.set("xalign", 0.0f,
              "mnemonic-widget", location);
    label_sizes.add_widget(label);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(location, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, 0, 0, 0);
    ++rows;
    
    page.attach(location.extras, 0, 2, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, 0, 0, 0);
    ++rows;
    
    w = new DejaDup.ConfigBool(DejaDup.ENCRYPT_KEY, _("Backup files are _encrypted"));
    page.attach(w, 0, 2, rows, rows + 1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                Gtk.AttachOptions.FILL, 0, 0);
    ++rows;
    
    page.show_all();

    // Now make sure to reserve the excess space that the hidden bits of
    // ConfigLocation will need.
    Gtk.Requisition req, hidden;
    page.get_preferred_size(null, out req);
    hidden = location.hidden_size();
    req.width = req.width + hidden.width;
    req.height = req.height + hidden.height;
    page.set_size_request(req.width, req.height);

    return page;
  }
  
  protected override void add_custom_config_pages()
  {
    var page = make_backup_location_page();
    append_page(page);
    set_page_title(page, _("Preferences"));
  }
  
  Gtk.Widget make_query_backend_page()
  {
    query_progress_bar = new Gtk.ProgressBar();
    
    var page = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    page.set("child", query_progress_bar,
             "border-width", 12);
    page.child_set(query_progress_bar, "expand", false);
    
    return page;
  }
  
  Gtk.Widget make_date_page()
  {
    date_store = new Gtk.ListStore(2, typeof(string), typeof(string));
    date_combo = new Gtk.ComboBoxText();
    date_combo.model = date_store;
    
    var date_label = new Gtk.Label(_("_Date:"));
    date_label.set("mnemonic-widget", date_combo,
                   "use-underline", true,
                   "xalign", 0.0f);
    
    var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
    hbox.set("child", date_label,
             "child", date_combo);
    
    var page = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
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
    
    cust_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
    cust_box.set("child", cust_label,
                 "child", cust_button,
                 "sensitive", false);
    
    var page = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    page.set("child", orig_radio,
             "child", cust_radio,
             "child", cust_box,
             "border-width", 12);
    page.child_set(orig_radio, "expand", false);
    page.child_set(cust_radio, "expand", false);
    page.child_set(cust_box, "expand", false);
    
    return page;
  }
  
  protected override Gtk.Widget? make_confirm_page()
  {
    int rows = 0;
    Gtk.Widget label, w;
    
    confirm_table = new Gtk.Table(rows, 3, false);
    var page = confirm_table;
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    
    label = new Gtk.Label(_("Backup location:"));
    label.set("xalign", 0.0f);
    w = new DejaDup.ConfigLabelLocation();
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(w, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    
    label = new Gtk.Label(_("Encrypted:"));
    label.set("xalign", 0.0f);
    w = new DejaDup.ConfigLabelBool(DejaDup.ENCRYPT_KEY);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(w, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    
    confirm_date_label = new Gtk.Label(_("Restore date:"));
    confirm_date_label.set("xalign", 0.0f);
    confirm_date = new Gtk.Label("");
    confirm_date.set("xalign", 0.0f);
    confirm_date_row = rows;
    page.attach(confirm_date_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(confirm_date, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    
    confirm_location_label = new Gtk.Label(_("Restore folder:"));
    confirm_location_label.set("xalign", 0.0f);
    confirm_location = new Gtk.Label("");
    confirm_location.set("xalign", 0.0f);
    confirm_location_row = rows;
    page.attach(confirm_location_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(confirm_location, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    
    confirm_files_label = new Gtk.Label("");
    confirm_files_label.set("xalign", 0.0f, "yalign", 0.0f);
    confirm_files = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    confirm_files.set("homogeneous", true);
    confirm_files_row = rows;
    page.attach(confirm_files_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    page.attach(confirm_files, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    
    return page;
  }
  
  void add_query_backend_page()
  {
    var page = make_query_backend_page();
    append_page(page, Type.PROGRESS);
    set_page_title(page, _("Checking for Backups…"));
    query_progress_page = page;
  }
  
  void add_date_page()
  {
    var page = make_date_page();
    append_page(page);
    set_page_title(page, _("Restore from When?"));
    date_page = page;
  }
  
  void add_restore_dest_page()
  {
    var page = make_restore_dest_page();
    append_page(page);
    set_page_title(page, _("Restore to Where?"));
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

    realize();
    var xid = Gdk.X11Window.get_xid(this.get_window());

    var rest_op = new DejaDup.OperationRestore(restore_location, date,
                                               restore_files, (uint)xid);
    if (this.op_state != null)
      rest_op.set_state(this.op_state);

    return rest_op;
  }
  
  protected override string get_progress_file_prefix()
  {
    // Translators:  This is the word 'Restoring' in the phrase
    // "Restoring '%s'".  %s is a filename.
    return _("Restoring:");
  }

  bool is_same_day(TimeVal one, TimeVal two)
  {
    Date day1 = Date(), day2 = Date();
    day1.set_time_val(one);
    day2.set_time_val(two);
    return day1.compare(day2) == 0;
  }

  protected virtual void handle_collection_dates(DejaDup.OperationStatus op, List<string>? dates)
  {
    /*
     * Receives list of dates of backups and shows them to user
     *
     * After receiving list of dates at which backups were performed function
     * converts dates to TimeVal structures and later converts them to Time to
     * time to show them in nicely formate local form.
     */
    var timevals = new List<TimeVal?>();
    TimeVal tv = TimeVal();
    
    got_dates = true;
    date_store.clear();
    
    foreach (string date in dates) {
      if (tv.from_iso8601(date)) {
        timevals.append(tv);
      }
    }

    for (unowned List<TimeVal?>? i = timevals; i != null; i = i.next) {
      tv = i.data;

      string format = "%x";
      if ((i.prev != null && is_same_day(i.prev.data, tv)) ||
          (i.next != null && is_same_day(i.next.data, tv))) {
        // Translators: %x is the current date, %X is the current time.
        // This will be in a list with other strings that just have %x (the
        // current date).  So make sure if you change this, it still makes
        // sense in that context.
        format = _("%x %X");
      }

      Time t = Time.local(tv.tv_sec);
      string user_str = t.format(format);
      Gtk.TreeIter iter;
      date_store.prepend(out iter);
      date_store.@set(iter, 0, user_str, 1, tv.to_iso8601());
      date_combo.set_active_iter(iter);
    }
    
    // If we didn't see any dates...  Must not be any backups on the backend
    if (date_store.iter_n_children(null) == 0)
      show_error(_("No backups to restore"), null);
  }
  
  protected virtual void query_finished(DejaDup.Operation op, bool success, bool cancelled)
  {
    this.op_state = op.get_state();
    this.query_op = null;
    this.op = null;
    
    if (cancelled)
      do_close();
    else if (success)
      go_forward();
  }
  
  bool query_pulse()
  {
    query_progress_bar.pulse();
    return true;
  }
  
  protected async void do_query()
  {
    realize();
    var xid = Gdk.X11Window.get_xid(this.get_window());

    query_op = new DejaDup.OperationStatus((uint)xid);
    query_op.collection_dates.connect(handle_collection_dates);
    query_op.done.connect(query_finished);
    op = query_op;
    op.backend.mount_op = new MountOperationAssistant(this);
    op.passphrase_required.connect(get_passphrase);
    op.raise_error.connect((o, e, d) => {show_error(e, d);});

    query_op.start();
  }
  
  protected override void do_prepare(Assistant assist, Gtk.Widget page)
  {
    base.do_prepare(assist, page);
    
    if (query_timeout_id > 0) {
      Source.remove(query_timeout_id);
      query_timeout_id = 0;
    }
    
    if (page == date_page) {
      // Hmm, we never got a date from querying the backend, but we also
      // didn't hit an error (since we're about to show this page, and not
      // the summary/error page).  Skip the date portion, since the backend
      // must not be capable of giving us dates (duplicity < 0.5.04 couldn't).
      if (!got_dates)
        skip();
    }
    else if (page == restore_dest_page) {
      // If we're doing a known-file-set restore, assume user wants same-location
      // restore.
      if (restore_files != null)
        skip();
    }
    else if (page == confirm_page) {
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
          confirm_location.label = DejaDup.get_file_desc(File.new_for_path(restore_location));
        
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

        confirm_files.foreach((w) => {DejaDup.destroy_widget(w);});
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
        set_page_title(page, _("Restore Failed"));
      else {
        set_page_title(page, _("Restore Finished"));
        if (restore_files == null)
          summary_label.label = _("Your files were successfully restored.");
        else
          summary_label.label = ngettext("Your file was successfully restored.",
                                         "Your files were successfully restored.",
                                         restore_files.length());
      }
    }
    else if (page == progress_page) {
      set_page_title(page, _("Restoring…"));
    }
    else if (page == query_progress_page) {
      query_progress_bar.fraction = 0;
      query_timeout_id = Timeout.add(250, query_pulse);
      if (query_op != null && query_op.needs_password) {
        // Operation is waiting for password
        provide_password();
      }
      else if (query_op == null)
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

