/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2010 Urban Skudnik <urban.skudnik@gmail.com>

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

public class DeletedFile {
  /*
   * Class whose instances hold information and track status of deleted file.
   *
   * After providing full file path and time of when was file last seen, instances
   * can access pretty file name and mark file for restore.
   * 
   * @param //string// ''name'' Full path name of file
   * @param //Time// ''deleted'' Information when was file deleted
   */
  public string name {get; set;}
  public Time deleted {get; set;}
  public bool restore {get; set; default = false;}

  public DeletedFile(string name, Time deleted) {
    this.name = name;
    this.deleted = deleted;
  }

  public string filename() {
    var splited_fn = this.name.split("/");
    return splited_fn[splited_fn.length-1];
  }

  public string queue_format() {
    var file = this.name;
    var time = this.deleted.format("%s");
    return @"$file $time";
  }
}

public class AssistantRestoreMissing : AssistantOperation {
  /*
   * Assistant for showing deleted files
   *
   * Assistant for showing deleted files. Execution flow goes as follows:
   * 
   * 1. AssistantRestoreMissing is called with //File// ''list_dir'' directory
   * 2. //void// do_prepare prepares listfiles_page and runs do_query_collection_dates that initializes query operation for collections dates. Results of query operation are returned to handle_collection_dates in one batch.
   * 3. handle_collection_dates fills the //PriorityQueue// ''backups_queue'' with //Time// values of backup dates, scans provided //File// ''list_dir'' with files that are currently located in directory and runs do_query_files_at_date
   * 4. do_query_files_at_date begins query operation for list-current-files at specific times and returns the results to handle_listed_files.  
   * 5. handle_listed_files appends files to the list of deleted files with appropriate controls.
   * 6. When OperationFiles finishes, query_files_finished releases variables and, if required, calls do_query_files_at_date. 
   * 7. After user selects files that he wishes to restore, he moves to confirmation page and starts the restore operation
   * 
   * @param //File// ''list_dir'' Directory whose deleted files will be shown.
   */
  private File list_directory;

  private bool backups_queue_filled = false;
  private static int compare_time(Time a, Time b) {
    /*
     * Compare function for backups queue
     *
     * Default comparing for queue goes from oldest to newest so we use our own
     * compare function to reverse that ordering and proceed from newest to oldest
     * since it is far more likely that user deleted file in recent history.
     *
     * @param //Time// ''a'', ''b'' Time objects
     */
    var a_epoch = a.format("%s").to_int();
    var b_epoch = b.format("%s").to_int();
    if (a_epoch < b_epoch)
      return 1;
    else if (a_epoch == b_epoch)
      return 0;
    else
      return -1;
  }

  /*
    If user moves forward while OperationFiles is runing, code cleanup stops the current operation
    and stops recursive loop without the need to clear backups_queue. If user decides to go back, 
    OperationFiles will continue with NEXT item in backups_queue.
  */
  private bool scan_queue = true;
  private bool cancel_assistant = false;
  private Sequence<Time?> backups_queue = new Sequence<Time?>(g_free);
  private HashTable<string, DeletedFile> restore_queue = new HashTable<string, DeletedFile>(str_hash, str_equal);

  private HashTable<string, string> allfiles_prev;
  private GenericArray<DeletedFile> file_status = new GenericArray<DeletedFile>();

  DejaDup.OperationFiles query_op_files;
  DejaDup.OperationStatus query_op_collection_dates;
  DejaDup.Operation.State op_state; // Shared between operations

  Gtk.Widget listfiles_page;
  Gtk.TreeIter deleted_iter;
  Gtk.ListStore listmodel;
  Gtk.ScrolledWindow sw_restore_files;
  Gtk.Label list_dir_label;

  /* List files page */
  //Gtk.Label current_scan_date = new Gtk.Label(_("Starting..."));
  Gtk.Label current_scan_date;
  Gtk.Spinner spinner = new Gtk.Spinner();
  
  /* Confirmation page related widgets */
  Gtk.Label label;
  Gtk.Label restore_files_label;
  Gtk.Table restore_files_table;
  /*
    Gtk.Table in Glade needs to be set at least to 1 at start. When we update
    our table we start from 0 so that we always resize table to correct size without the need for special case.
   */
  int restore_files_table_rows = 0;
  
  public AssistantRestoreMissing(File list_dir) {
    list_directory = list_dir;
  }

  construct
  {
    title = _("Restore");
    apply_text = _("_Restore");
  }

  private string? get_ui_file(string ui_file) {
    var sysdatadirs = GLib.Environment.get_system_data_dirs();
    foreach (var sysdir in sysdatadirs) {
      var p = Path.build_filename(sysdir, Config.PACKAGE, "ui", ui_file);
      var file = File.new_for_path(p);
      if (file.query_exists(null))
        return p;
    }
    return null;
  }

  private HashTable<string, string> files_in_directory() {
    /*
     * Function lists all files that are currently located in the directory.
     *
     * Function scans directory that was provided to it through
     * command line children and returns an array of strings populated
     * by file names of folder and files.
     */
    var files = new HashTable<string, string> (str_hash, str_equal);

    try {
      var enumerator = list_directory.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME, 0, null);
      FileInfo fileinfo;
      while ((fileinfo = enumerator.next_file(null)) != null)
        files.insert(list_directory.get_path() + "/" + fileinfo.get_name(), null);
    }
    catch (Error e){
      warning("%s\n", e.message);
    }
    return files;
  }

  Gtk.Widget? make_listfiles_page() {
    /*
     * Build list files (introduction) page which shows deleted files.
     *
     * Build list files page from a Glade template and attach various dynamic
     * components to it. Deleted files are dynamically added on-the-fly by
     * applicable functions.
     */

      // Hack; we need ''page'' because window needs to be reparented to be shown.
      var page = new Gtk.Table(1, 1, false);
      page.name = "listfiles_page";
      var builder = new Gtk.Builder();
      try {
        string gf = get_ui_file("restore-missing.ui");
        if (gf == null) {
          warning("Error: Could not find interface file.");
          return null;
        }
        builder.add_from_file(gf);
        builder.connect_signals(this);
        
        var window = builder.get_object("viewport") as Gtk.Widget;
        var filelistwindow = builder.get_object("filelistwindow") as Gtk.ScrolledWindow;
        var status_table = builder.get_object("backup_table") as Gtk.Table;
        var progress_table = builder.get_object("status_box") as Gtk.Table;
        current_scan_date = builder.get_object("status_word") as Gtk.Label;

        /* Add backup and scan information */
        this.list_dir_label = new Gtk.Label("");
        status_table.attach(this.list_dir_label, 1, 2, 0, 1, Gtk.AttachOptions.FILL, 0, 0, 0);

        /* Spinner */
        progress_table.attach(this.spinner, 0, 1, 0, 1, Gtk.AttachOptions.FILL, 0, 0, 0);
        this.spinner.set_size_request(20, 20);
       
        this.listmodel = new Gtk.ListStore (3, typeof (bool), typeof (string), typeof (string));
        var treeview = new Gtk.TreeView.with_model (this.listmodel);
        var toggle = new Gtk.CellRendererToggle();
        
        toggle.toggled.connect ((toggle, path) => {
          /*
           * Function for toggling state of checkbox
           */
          if (!this.file_status.get(path.to_int()).restore)
            this.file_status.get(path.to_int()).restore = true;
          else
            this.file_status.get(path.to_int()).restore = false;

          allow_forward_if_any_selected();
          
          var tree_path = new Gtk.TreePath.from_string (path);
          this.listmodel.get_iter (out this.deleted_iter, tree_path);
          this.listmodel.set(this.deleted_iter, 0, !toggle.active);
        });

        treeview.insert_column_with_attributes(-1, "    ", toggle, "active", 0);
        treeview.insert_column_with_attributes(-1, _("File"), new Gtk.CellRendererText(), "text", 1);
        treeview.insert_column_with_attributes(-1, _("Last seen"), new Gtk.CellRendererText(), "text", 2);
 
        treeview.set_headers_visible (true);

        filelistwindow.add_with_viewport(treeview);
        window.reparent(page);
        return page;
      } catch (Error err) {
        warning("Error: %s", err.message);
        return null;
      }
  }

  void allow_forward_if_any_selected()
  {
    for (int i = 0; i < file_status.length; ++i) {
      if (file_status[i].restore) {
        allow_forward(true);
        return;
      }
    }
    allow_forward(false);
  }

  void add_listfiles_page() {
    var page = make_listfiles_page();
    append_page(page);
    set_page_title(page, _("Restore Missing Files"));
    listfiles_page = page;
  }

  protected override void add_setup_pages() {
    add_listfiles_page();
  }

  protected override void do_prepare(Assistant assist, Gtk.Widget page) {
    if (page == listfiles_page) {
      list_dir_label.label = list_directory.get_parse_name();
      if (!scan_queue) {
        do_query_files_at_date();
        scan_queue = true;
      }
      else {
        if (query_op_collection_dates != null && query_op_collection_dates.needs_password) {
          provide_password();
        }
        else if (query_op_files != null && query_op_files.needs_password) {
          provide_password();
        }
        else if (!backups_queue_filled) {
          do_query_collection_dates();
        }
      }

      // Doing this in idle is a bit of a hack.  We do this because Assistant
      // doesn't add the buttons until after this prepare call.
      Idle.add(() => {allow_forward_if_any_selected(); return false;});
    }
    
    else if (page == confirm_page) {
    /*
     * We need to destroy the existing table and redraw current one to draw
     * the confirmation page.
     */
      scan_queue = false;

      restore_files_table.destroy();
      restore_files_table = new Gtk.Table(1, 1, false);
      restore_files_table_rows = 0;
      
      for (int i = 0; i < file_status.length; ++i) {
        var delfile = file_status[i];
        if (delfile.restore)
        {
          restore_queue.insert(delfile.name, delfile);

          restore_files_table_rows++;
          restore_files_table.resize(restore_files_table_rows, 1);
          
          label = new Gtk.Label(delfile.filename());
          label.set("xalign", 0.0f);
          label.show(); // By default, labels are hidden, therefore we show it.
          restore_files_table.attach(label, 0, 1, this.restore_files_table_rows-1, this.restore_files_table_rows, Gtk.AttachOptions.FILL, 0, 0, 0);
        }
      }

      // Use appropriate form
      restore_files_label.set_text(ngettext("File to restore:",
                                            "Files to restore:",
                                            restore_files_table_rows));
      restore_files_table.show();
      sw_restore_files.add_with_viewport(restore_files_table);
    }
    else if (page == progress_page) {
      set_page_title(page, _("Restoring…"));
    }
    else if (page == summary_page) {
      if (error_occurred)
        set_page_title(page, _("Restore Failed"));
      else {
        set_page_title(page, _("Restore Finished"));

        /* Count the number of files that had to be restored */
        var numdels = 0; // Number of deleted files
        for (int i = 0; i < file_status.length; ++i) {
          var delfile = file_status[i];
          if (delfile.restore) {
            numdels++;
          }
        }

        summary_label.label = ngettext(_("Your file was successfully restored."),
                                         _("Your files were successfully restored."),
                                         numdels);
      }
    }
    base.do_prepare(assist, page);
  }

  protected void handle_listed_files(DejaDup.OperationFiles op, string date, string file) {
      /*
       * Handler for each line returned by duplicity individually
       *
       * Duplicity returns each file as a separate line that has to be handled individually.
       * We therefore check if file in path of directory, if it exists and whether or not it has not been seen before
       * and attach it to our TreeView model if all conditions are met.
       *
       * @param //DejaDup.OperationFiles// ''op'' Operation that is currently running
       * @param //string// ''date'' Time of last change of file 
       * @param //string// ''file'' Full path of file 
       */
    string filestr = @"/$file";
    if (this.list_directory.get_path() in filestr && this.list_directory.get_path() != filestr) {
      var fileobj = File.new_for_path(filestr);

      if (!fileobj.query_exists(null) && !this.allfiles_prev.lookup_extended(filestr, null, null)) {
        if(fileobj.has_parent(this.list_directory)) {
          var fs = new DeletedFile(filestr, op.time);

          this.file_status.add(fs);

          this.listmodel.append (out this.deleted_iter);
          this.listmodel.set (this.deleted_iter, 0, false, 1, fs.filename(), 2, op.time.format("%c"));

          this.allfiles_prev.insert(filestr, null);
        }
      }
    }
  }

  protected void handle_collection_dates(DejaDup.OperationStatus op, GLib.List<string>? dates)
  {
    /*
     * Handle collection dates
     *
     * Collection dates are returned as a single list of strings file timestamps of backup.
     * Timestamps are in ISO 8601 format and are first read and converted to //Time// objects and then
     * added to backups_queue.
     *
     * @param //DejaDup.OperationStatus// ''op'' Operation currently being run
     * @param //GLib.List<string>?// ''dates'' ISO 8601 dates of backups.
     */
    TimeVal tv = TimeVal();

    if (!this.backups_queue_filled) {
      foreach(var date in dates) {
        if (tv.from_iso8601(date)) {
          Time t = Time.local(tv.tv_sec);
          this.backups_queue.insert_sorted(t, (CompareDataFunc)compare_time);
        }
      }

      this.allfiles_prev = files_in_directory();
      this.backups_queue_filled = true;
    
      this.spinner.start();
    }
  }

  protected void do_query_collection_dates()
  {
    /*
     * Initialize query operation for collection dates.
     *
     * Initializes query operation and links appropriate signals for when operation
     * finishes and when it receives duplicity's output.
     */
    realize();
    var xid = Gdk.x11_drawable_get_xid(this.window);
      
    query_op_collection_dates = new DejaDup.OperationStatus((uint)xid);
    query_op_collection_dates.collection_dates.connect(handle_collection_dates);
    query_op_collection_dates.done.connect(query_collection_dates_finished);
    
    if (mount_op == null)
      mount_op = new MountOperationAssistant(this);

    op = query_op_collection_dates;
    op.backend.mount_op = mount_op;
    op.passphrase_required.connect(get_passphrase);
    op.raise_error.connect((o, e, d) => {show_error(e, d);});

    query_op_collection_dates.start();
  }
    
  protected void do_query_files_at_date()
  {
    /*
     * Initializes query operation for list-current-files at specific date 
     *
     * Initializes query operation, updates list files page with current date of scan
     * in human semi-friendly form and connect appropriate signals. 
     */
    if (cancel_assistant) {
      do_close();
      return;
    }

    // Don't start if queue is empty.
    if (backups_queue.get_length() == 0) {
      query_files_finished(query_op_files, true, false);
      return;
    }
    
    var begin = backups_queue.get_begin_iter();
    var etime = begin.get();
    backups_queue.remove(begin);

    /* Update progress */
    int tepoch = etime.format("%s").to_int();
    TimeVal ttoday = TimeVal();
    ttoday.get_current_time();
    int ttodayi = (int) ttoday.tv_sec;
    
    string worddiff;
    int tdiff =  (ttodayi - tepoch)/60/60; // Hours
    if (tdiff / 24 == 0 ) {
      worddiff = _("Scanning for files from yesterday...");
    }
    else if (tdiff / 24 / 7 == 0) {
      worddiff = _("Scanning for files from last week...");
    }
    else if (tdiff / 24 / 30 == 0) {
    worddiff = _("Scanning for files from last month...");
    }
    else if (tdiff / 24 / 30 >= 1 && tdiff / 24 / 30 <= 12) {
      int n = tdiff / 24 / 30;
      worddiff = ngettext("Scanning for files from about a month ago...",
                          "Scanning for files from about %d months ago...".printf(n),
                          n);
    }
    else {
      int n = tdiff / 24 / 30 / 12;
      worddiff = ngettext("Scanning for files from about a years ago...",
                          "Scanning for files from about %d years ago...".printf(n),
                          n);
    }

    this.current_scan_date.set_text(worddiff);

    realize();
    var xid = Gdk.x11_drawable_get_xid(this.window);
    
    /* Time object does not support GObject-style construction */
    query_op_files = new DejaDup.OperationFiles((uint)xid, etime, list_directory);
    query_op_files.listed_current_files.connect(handle_listed_files);
    query_op_files.done.connect(query_files_finished);
    
    op = query_op_files;
    op.passphrase_required.connect(get_passphrase);
    op.raise_error.connect((o, e, d) => {show_error(e, d);});

    op.set_state(op_state); // share state between ops
    
    query_op_files.start();
  }
  
  protected void query_collection_dates_finished(DejaDup.Operation op, bool success, bool cancelled) {
    query_op_collection_dates = null;
    op_state = this.op.get_state();
    this.op = null;
    
    if (cancelled)
      do_close();
    else
      do_query_files_at_date();
  }

  protected override void do_cancel() {
      /*
       * Mark cancel_assistant as true so that all other operations are blocked.
       *
       * do_cancel kills current operation but because we are still running recursion
       * and at the end of each operation still check if we have anything to deleted,
       * we need to manually mark entire assistant as canceled so that no further
       * operations are called.
       */
    cancel_assistant = true;
    base.do_cancel();
  }

  protected override void set_op_icon_name()
  {
    icon_name = "deja-dup-restore";
  }

  protected override void apply_finished(DejaDup.Operation op, bool success, bool cancelled)
  {
    /*
     * Ran after assistant finishes applying restore operation.
     *
     * After assistant finishes with initial OperationRestore, apply_finished is called. Afterwards we
     * check if restore_queue is empty and if not, rerun apply function. If it is, we move to
     * summary page.
     */
    //status_icon = null; PRIV PARAMETER - FIXIT!
    this.op = null;

    if (cancelled) {
      if (success) // stop (resume later) vs cancel
        Gtk.main_quit();
      else {
        do_close();
      }
    }
    else {
      if (success) {
        succeeded = true;
        if (this.restore_queue.size() > 0) {
          base.do_apply();
        } else {
          go_to_page(summary_page);
        }
      }
      else // show error
        force_visible(false);
    }
  }
  
  protected void query_files_finished(DejaDup.Operation? op, bool success, bool cancelled)
  {
    query_op_files = null;
    this.op = null;
    
    if (backups_queue.get_length() == 0) {
      this.spinner.stop();
      this.spinner.destroy();
      this.current_scan_date.set_text(_("Scanning finished"));
      scan_queue = false;
    }
    else {
      if (scan_queue)
        do_query_files_at_date();
    }
  }

  protected override Gtk.Widget? make_confirm_page(){
      /*
       * Build confirmation page and add various dynamic elements to Glade template
       */
    var page = new Gtk.Table(1, 1, false);
    page.name = "confirm_page";
    var builder = new Gtk.Builder();
    try {
      string gf = get_ui_file("restore-missing-confirm.ui");
      if (gf == null) {
        warning("Error: Could not find interface file.");
        return null;
      }
      builder.add_from_file(gf);      
      var window = builder.get_object("viewport") as Gtk.Widget;
      var backup_source_properties = builder.get_object("backup_properties") as Gtk.Table;
      sw_restore_files = builder.get_object("sw-restore-files") as Gtk.ScrolledWindow;
      restore_files_label = builder.get_object("restore_files_label") as Gtk.Label;
      
      Gtk.Widget w;

      w = new DejaDup.ConfigLabelLocation();
      backup_source_properties.attach(w, 1, 2, 0, 1, Gtk.AttachOptions.FILL, 0, 0, 0);

      w = new DejaDup.ConfigLabelBool(DejaDup.ENCRYPT_KEY);
      backup_source_properties.attach(w, 1, 2, 1, 2, Gtk.AttachOptions.FILL, 0, 0, 0);

      window.reparent(page);
      return page;
    } catch (Error err) {
      warning("Error: %s", err.message);
      return null;
    }
  }

  protected override DejaDup.Operation create_op()
  {
    /*
     * Creates operation that is then called by do_apply.
     */
    realize();
    var xid = Gdk.x11_drawable_get_xid(this.window);

    var begin = HashTableIter<string, DeletedFile>(restore_queue);
    DeletedFile restore_file;
    begin.next(null, out restore_file);
    begin.remove();

    /*
    OperationRestore usually takes list of file so restore. Since it is high 
    probability that if we will restore multiple files, they will be from different dates,
    we simply call OperationRestore multiple times with single date and file.
    */
    
    var restore_files = new GLib.List<File>(); 
    restore_files.append(File.new_for_path(restore_file.name));
    
    var rest_op = new DejaDup.OperationRestore("/", 
                                               restore_file.deleted.format("%s"),
                                               restore_files,
                                               (uint)xid);
    rest_op.set_state(op_state);
    return rest_op;
  }
    
  protected override string get_progress_file_prefix(){
    return _("Restoring");
  }
}
