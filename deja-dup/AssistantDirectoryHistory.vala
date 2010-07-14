using GLib;
using Gee;

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

public class AssistantDirectoryHistory : AssistantOperation {
	/*
	 * Assistant for showing deleted files
	 *
	 * Assistant for showing deleted files. Execution flow goes as follows:
	 * 
	 * 1. AssistantDirectoryHistory is called with //File// ''list_dir'' directory
	 * 2. //void// do_prepare prepares listfiles_page and runs do_query_collection_dates that initializes query operation for collections dates. Results of query operation are returned to handle_collection_dates in one batch.
	 * 3. handle_collection_dates fills the //PriorityQueue// ''backups_queue'' with //Time// values of backup dates, scans provided //File// ''list_dir'' with files that are currently located in directory and runs do_query_files_at_date
	 * 4. do_query_files_at_date begins query operation for list-current-files at specific times and returns the results to handle_listed_files.  
	 * 5. handle_listed_files appends files to the list of deleted files with appropriate controls.
	 * 6. When OperationFiles finishes, query_files_finished releases variables and, if required, calls do_query_files_at_date. 
	 * 7. After user selects files that he wishes to restore, he moves to confirmation page and starts the restore operation
	 * 
	 * 
	 * 
	 * 
	 * 
	 * 
	 * 
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
	private PriorityQueue<Time?> backups_queue = new PriorityQueue<Time?>((CompareFunc) compare_time);
	private PriorityQueue<DeletedFile?> restore_queue = new PriorityQueue<DeletedFile?>();

	private ArrayList<string> allfiles_prev = new ArrayList<string>();
	private ArrayList<DeletedFile?>	file_status = new ArrayList<DeletedFile?>();

	DejaDup.OperationFiles query_op_files;
	DejaDup.OperationStatus query_op_collection_dates;
  DejaDup.Operation.State op_state;

	Gtk.Widget page;
	Gtk.Widget listfiles_page;
	Gtk.TreeIter deleted_iter;
	Gtk.TreeIter restoreiter;
	Gtk.ListStore listmodel;
	Gtk.ListStore restoremodel;

	/* List files page */
	Gtk.Label current_scan_date = new Gtk.Label(_("Starting..."));
	Gtk.Spinner spinner = new Gtk.Spinner();
	
	/* Confirmation page related widgets */
	Gtk.Label label;
	Gtk.Table restore_files_table;
	/*
		Gtk.Table in Glade needs to be set at least to 1 at start. When we update
		our table we start from 0 so that we always resize table to correct size without the need for special case.
	 */
	int restore_files_table_rows = 0;
	
	public AssistantDirectoryHistory(File list_dir) {
			list_directory = list_dir;
	}

	private ArrayList<string>? files_in_directory() {
		/*
		 * Function lists all files that are currently located in the directory.
		 *
		 * Function scans directory that was provided to it through
		 * command line children and returns an array of strings populated
		 * by file names of folder and files.
		 */
		//File directory = File.new_for_path(dirlocation);
		var file_list = new ArrayList<string> ();

		try {
			var enumerator = this.list_directory.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME, 0, null);
			FileInfo fileinfo;
			while ((fileinfo = enumerator.next_file(null)) != null){
				file_list.add(this.list_directory.get_path() + "/" + fileinfo.get_name());
			}
			return file_list;
		} catch(Error err){
			warning("Error: %s\n", err.message);
			return null;
		}
	}

	/*[CCode (instance_pos = -1)]
	public void on_restoretoggle(Gtk.CellRendererToggle checkbox, int path) {
		checkbox.set_active(true);
	}*/

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
				builder.add_from_file("interface/listfiles-crt-out.ui");
				builder.connect_signals(this);
				
				var window = builder.get_object("viewport") as Gtk.Widget;
				var filelistwindow = builder.get_object("filelistwindow") as Gtk.ScrolledWindow;
				var status_table = builder.get_object("backup_table") as Gtk.Table;
				var progress_table = builder.get_object("progress_table") as Gtk.Table;

				/* Add backup and scan information */
				/* Backup source */
				Gtk.Widget w = new DejaDup.ConfigLabelLocation();
				status_table.attach(w, 1, 2, 0, 1, Gtk.AttachOptions.FILL, 0, 0, 0);

				/* Spinner */
				progress_table.attach(this.spinner, 1, 2, 0, 1, Gtk.AttachOptions.FILL, 0, 0, 0);

				/* Current date of scan */
				progress_table.attach(this.current_scan_date, 2, 3, 0, 1, Gtk.AttachOptions.FILL, 0, 0, 0);
				
				this.listmodel = new Gtk.ListStore (3, typeof (bool), typeof (string), typeof (string));
				var treeview = new Gtk.TreeView.with_model (this.listmodel);
				//treeview.set_model(this.listmodel);
				var toggle = new Gtk.CellRendererToggle();
				toggle.toggled.connect ((toggle, path) => {
					  /*
						 * Function for toggling state of checkbox
						 */
					if (!this.file_status[path.to_int()].restore)
						this.file_status[path.to_int()].restore = true;
					else
						this.file_status[path.to_int()].restore = false;
					
					var tree_path = new Gtk.TreePath.from_string (path);
          this.listmodel.get_iter (out this.deleted_iter, tree_path);
          this.listmodel.set(this.deleted_iter, 0, !toggle.active);
        });

				treeview.insert_column_with_attributes(-1, "", toggle, "active", 0);
				treeview.insert_column_with_attributes(-1, "File name", new Gtk.CellRendererText(), "text", 1);
				treeview.insert_column_with_attributes(-1, "Deleted", new Gtk.CellRendererText(), "text", 2);
 
        treeview.set_headers_visible (true);

				filelistwindow.add_with_viewport(treeview);

				/*
					we have do_prepare, stupid!
					this.forward.connect((assist) => {
					uint pathlenght;
					string path;
					string pathr;
					uint pathlenght2;
					string path2;
					string pathr2;
					assist.current.data.page.path(out pathlenght, out path, out pathr);
					listfiles_page.path(out pathlenght2, out path2, out pathr2);
					//stdout.printf("\nFORWARD! name: %s\n %s \n %s\n\n", assist.current.data.page.name, path, path2);
					if (assist.current.data.page.name == "confirm_page") {
						stdout.printf("\n\n\nlistfilespage mamo! do magic misko!\n");
						foreach(var delfile in this.file_status) {
							if (delfile.restore)
							{
								stdout.printf("OFFERING: %s\n\n", delfile.name);
								//this.restore_queue.push_tail(delfile.queue_format());
								this.restore_queue.offer(delfile);
								
								this.restoremodel.append (out this.restoreiter);
        				this.restoremodel.set(this.restoreiter, 0, delfile.name);
							}
						}
						this.backups_queue.clear();
					}
				});*/						
				window.reparent(page);
				return page;
			} catch (Error err) {
				warning("Error: %s", err.message);
				return null;
			}
	}

	void add_listfiles_page() {
		var page = make_listfiles_page();
		append_page(page);
		set_page_title(page, _("Deleted Files"));
		listfiles_page = page;
		//selectfiles_page = page;
	}		

	//private void deleted_files(Gtk.ListStore listmodel) {
	//	stdout.printf("\n\ndeleted files\n\n");

		// First, the simples - files from directory
		//var fid = files_in_directory();

		// Second - get collection dates
		/*if (backup_dates == null) {
			stdout.printf("backup_dates == null");
			if (!collection_dates_query_in_progress) {
					stdout.printf("collection_dates_query_in_progress = false");
					do_query_collection_dates();
			}*/
			
			/*foreach(string date in this.backup_dates) {
				stdout.printf("%s\n", date);
			}	*/										 
		//	stdout.printf("gremo naprej, timeout ker ni podatkov");
			/*Timeout.add_seconds(1, () => {
					deleted_files(listmodel, true);
					return false;
			});*/
			/*return;
		} else {
			stdout.printf("we have backup_dates!");
			foreach(string date in backup_dates){
				stdout.printf("datum: %s\n", date);
			}
		}*/

		// Third
	//}

	protected override void add_setup_pages() {
		add_listfiles_page();
		//add_restorefiles_page();
	}

	/*void add_restorefiles_page() {
		var page = make_restorefiles_page();
		append_page(page);
		set_page_title(page, _("About to restore"));
		//selectfiles_page = page;
	}*/

	protected override void do_prepare(Assistant assist, Gtk.Widget page) {
		if (page == listfiles_page) {
			//forward_button.set_label("Confirm");
			if (!scan_queue) {
				do_query_files_at_date();
				scan_queue = true;
			}
			else {
				if (op != null && op.needs_password){
					provide_password();
				}	
				else if (op == null) {
					do_query_collection_dates();
				}
			}
		}
		
		else if (page == confirm_page) {
			scan_queue = false;
			
			foreach(var delfile in this.file_status) {
				if (delfile.restore)
				{
					//stdout.printf("number of relevent rows: %u", this.restore_files_table.nrows);
					//this.restore_queue.push_tail(delfile.queue_format());
					this.restore_queue.offer(delfile);
					//stdout.printf(restore_files_table);
					this.restore_files_table_rows++;
					this.restore_files_table.resize(this.restore_files_table_rows, 1);
					
					label = new Gtk.Label(delfile.filename());
					label.set("xalign", 0.0f);
					label.show();
					this.restore_files_table.attach(label, 0, 1, this.restore_files_table_rows-1, this.restore_files_table_rows, Gtk.AttachOptions.FILL, 0, 0, 0);
					/*this.restoremodel.append (out this.restoreiter);
        	this.restoremodel.set(this.restoreiter, 0, delfile.name);*/
				}
			}
			//this.backups_queue.clear();
		}
		else if (page == summary_page) {
			if (error_occurred)
        set_page_title(page, _("Restore Failed"));
      else {
        set_page_title(page, _("Restore Finished"));

				/* Count the number of files that had to be restored */
				var numdels = 0; // Number of deleted files
				foreach(var delfile in this.file_status) {
					if (delfile.restore) {
						numdels++;
					}
				}

				summary_label.label = ngettext("Your file was successfully restored.",
                                         "Your files were successfully restored.",
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

			if (!fileobj.query_exists(null) && !this.allfiles_prev.contains(filestr)) {
				if(fileobj.has_parent(this.list_directory)) {
					var fs = new DeletedFile(filestr, op.time);

					this.file_status.add(fs);
					//var fileinfoobj = fileobj.query_info("standard::*", FileQueryInfoFlags.NONE, null);
					//stdout.printf("basename: %s", fileinfoobj.get_display_name());
					
					this.listmodel.append (out this.deleted_iter);
        	this.listmodel.set (this.deleted_iter, 0, false, 1, fs.filename(), 2, op.time.format("%c"));
				
					this.allfiles_prev.add(filestr);
				}
				/*if (file.query_file_type(0, null) == FileType.DIRECTORY) {

				}
				else if {
					
				}*/
			}

			/*if (!this.allfiles_prev.contains(filestr)) {
				//[this.list_directory.get_path().length:filestr.length]]
				
				var fs = new DeletedFile(filestr, op.time);
				this.file_status.add(fs);
					
				this.listmodel.append (out this.deleted_iter);
        this.listmodel.set (this.deleted_iter, 0, false, 1, fs.filename(), 2, op.time.format("%c"));
				
				this.allfiles_prev.add(filestr);
			}*/
		}

		/*if (this.files_at_epoch.has_key(op.time)) {
				//stdout.printf("%d", this.files_at_epoch.get(op.time));
				var flist = this.files_at_epoch.get(op.time);
				flist.add(datefilestr);
				//this.files_at_epoch.set(op.time, flist);
		} else {
			var nlist = new ArrayList<string>();
			nlist.add(datefilestr);
			this.files_at_epoch.set(op.time, nlist);
		}*/
	}

	protected void handle_collection_dates(DejaDup.OperationStatus op, GLib.List<string>? dates){
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
			//foreach(string date in dates){
			for(var i=dates.length()-1;i > 0;i--){
				if (tv.from_iso8601(dates.nth(i).data)) {
					Time t = Time.local(tv.tv_sec);
					this.backups_queue.offer(t);
				}
			}
		}

		this.allfiles_prev = files_in_directory();
		this.backups_queue_filled = true;

		this.spinner.start();
		do_query_files_at_date();
	}

	protected void do_query_collection_dates() {
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

		try {
      query_op_collection_dates.start();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      show_error(e.message, null); // not really user-friendly text, but ideally this won't happen
      query_collection_dates_finished(query_op_collection_dates, false, false);
    }
	}
		
	protected void do_query_files_at_date(){
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
		Time etime = backups_queue.poll();
		stdout.printf("\n\ndelamo iz backupa: %s\n\n", etime.format("%c"));
		/* Update progress */
		int tepoch = etime.format("%s").to_int();
		TimeVal ttoday = TimeVal();
		ttoday.get_current_time();
		int ttodayi = (int) ttoday.tv_sec;

		string worddiff;
		int tdiff =  (ttodayi - tepoch)/60/60; // Hours
		if (tdiff / 24 == 0 ) {
			worddiff = _("Last day");
		}
		else if (tdiff / 24 / 7 == 0) {
			worddiff = _("Last week");
		}
		else if (tdiff / 24 / 30 == 0) {
			stdout.printf("last month");
			worddiff = _("Last month");
		}
		else if (tdiff / 24 / 30 >= 1 && tdiff / 24 / 30 <= 12) {
			int n = tdiff / 24 / 30;
			if (n == 1)
				worddiff = _("About a month ago");
			else
				worddiff = _(@"About $n months ago");
		}
		else {
			int n = tdiff / 24 / 30 / 12;
			worddiff = _(@"About $n years ago");
		}

		this.current_scan_date.set_text(worddiff);
		
		if (mount_op == null)
      mount_op = new MountOperationAssistant(this);

		realize();
    var xid = Gdk.x11_drawable_get_xid(this.window);

		/* Time object does not support GObject-style construction */
		query_op_files = new DejaDup.OperationFiles((uint)xid, etime, list_directory);
		//query_op_files.time = etime;
		query_op_files.listed_current_files.connect(handle_listed_files);
    query_op_files.done.connect(query_files_finished);
		
    op = query_op_files;
    op.backend.mount_op = mount_op;
    op.passphrase_required.connect(get_passphrase);
    op.raise_error.connect((o, e, d) => {show_error(e, d);});
    
    try {
      query_op_files.start();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      show_error(e.message, null); // not really user-friendly text, but ideally this won't happen
      query_files_finished(query_op_files, false, false);
    }
	}

	protected void query_collection_dates_finished(DejaDup.Operation op, bool success, bool cancelled) {
    op_state = op.get_state();
    //this.query_op_files = null;
		query_op_collection_dates = null;
    op = null;
    
    if (cancelled)
      do_close();
    //else if (success)
      //go_forward();
		//	stdout.printf("success\n");
	}

	protected void query_wrapup() {
		//var deleted = new ArrayList<string>();

		/*var iterator = files_at_epoch.map_iterator();
		var has_next = iterator.first();

		allfiles_prev = iterator.get_value();
		has_next = iterator.next();
		while (has_next == true) {
			allfiles_cur = iterator.get_value();
			foreach(string pfile in allfiles_prev) {
				if (!allfiles_cur.contains(pfile)) {
					deleted.add(pfile);
				}
			}
			allfiles_prev = allfiles_cur;
			has_next = iterator.next();
		}

		foreach(var elem in deleted) {
			stdout.printf("%s", elem);
		}*/
		//printlist(deleted);
		//foreach(var edate in files_at_epoch){
			//stdout.printf("%s %s\n", edate.key,edate.value[3]);

			
			
			/*foreach(string file in edate.value) {
				stdout.printf("%s %s\n", edate.key,file);
			}*/
		//}
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
    op = null;

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
				if (this.restore_queue.size > 0) {
					base.do_apply();
				} else {
					go_to_page(summary_page);
				}
      }
      else // show error
        force_visible(false);
    }
  }
	
	protected void query_files_finished(DejaDup.Operation op, bool success, bool cancelled)
  {
		op_state = op.get_state();
    query_op_files = null;
		//this.query_op_collection_dates = null;
    op = null;
		
		if (backups_queue.size == 0) {
			this.spinner.stop();
			this.spinner.destroy();
			this.current_scan_date.set_text("Done!");
			scan_queue = false;
		}
		else {
			if (scan_queue)
				do_query_files_at_date();
		}
    
    if (cancelled)
      do_close();
    //else if (success)
      //go_forward();
			//stdout.printf("success\n");					
  }

	protected override Gtk.Widget? make_confirm_page(){
			/*
			 * Build confirmation page and add various dynamic elements to Glade template
			 */
		var page = new Gtk.Table(1, 1, false);
		page.name = "confirm_page";
		var builder = new Gtk.Builder();
		try {
			//builder.add_from_file("interface/restorefiles.glade");
			builder.add_from_file("interface/directory_history_confirmation_page.glade");
			//builder.connect_signals(this);
			
			var window = builder.get_object("viewport") as Gtk.Widget;
			var backup_source_properties = builder.get_object("backup_properties") as Gtk.Table;
			restore_files_table = builder.get_object("restore_files") as Gtk.Table;
			Gtk.Widget w;

			w = new DejaDup.ConfigLabelLocation();
			backup_source_properties.attach(w, 1, 2, 0, 1, Gtk.AttachOptions.FILL, 0, 0, 0);

			w = new DejaDup.ConfigLabelBool(DejaDup.ENCRYPT_KEY);
			backup_source_properties.attach(w, 1, 2, 1, 2, Gtk.AttachOptions.FILL, 0, 0, 0);

			//var label = new Gtk.Label("make_confirm_page");
			//label.set("xalign", 0.0f);
			//restore_files_table.attach(label, 0, 1, 0, 1, Gtk.AttachOptions.FILL, 0, 0, 0);
			/*label = new Gtk.Label("meh 2");
			label.set("xalign", 0.0f);
			restore_files_table.attach(label, 0, 1, 1, 2, Gtk.AttachOptions.FILL, 0, 0, 0);*/

			//int rows = 2;
			/*for (var i=0; i<50; i++){
				label = new Gtk.Label("row %d".printf(rows));
				label.set("xalign", 0.0f);
				rows++;
				restore_files_table.resize(rows, 1);
				restore_files_table.attach(label, 0, 1, rows, rows+1, Gtk.AttachOptions.FILL, 0, 0, 0);
			}*/
    	
			//stdout.printf(restore_files_table);
			
    	//label.set("xalign", 0.0f);
			//restore_files_table.attach(label, 0, 1, 1, 2, Gtk.AttachOptions.FILL, 0, 0, 0);
			//int rows = 0;
			//confirm_table = new Gtk.Table(rows, 1, false);
			

			/*var restorefiles = builder.get_object("restorefileswindow") as Gtk.ScrolledWindow;
			
			this.restoremodel = new Gtk.ListStore(1, typeof(string));
			var _tree_view = new Gtk.TreeView.with_model(this.restoremodel);
			
			_tree_view.insert_column_with_attributes(-1, "File name", new Gtk.CellRendererText(), "text", 0);

			_tree_view.set_headers_visible (true);	
			restorefiles.add_with_viewport(_tree_view);*/

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
		/*	var rest_op = new DejaDup.OperationRestore(restore_location, date,
                                               restore_files, (uint)xid);*/

		var restore_file = this.restore_queue.poll();
		//var restore_file = restore_queue.nth(0);
		//var restore_file = restore_queue.pop_head();
		//restore_queue.remove(restore_file);
		/*
		OperationRestore usually takes list of file so restore. Since it is high 
		probability that if we will restore multiple files, they will be from different dates,
		we simply call OperationRestore multiple times with singel date and file.
		*/
		
		var restore_files = new GLib.List<File>(); 
		//restore_files.append(File.new_for_path(restore_file.split(" ")[0]));
		restore_files.append(File.new_for_path(restore_file.name));
		//2001-07-15T04:09:38-07:00
		//restore_file.deleted.format("%FT%T%z"))
		//stdout.printf("name:%s time: %s", restore_file, restore_file.deleted.format("%FT%T%z"));
		//restore_file.split(" ")[1]]
		
		var rest_op = new DejaDup.OperationRestore("/", 
		    																			 restore_file.deleted.format("%s"),
		    																			 restore_files,
		    																			 (uint)xid);
		return rest_op;
  }
		
	protected override string get_progress_file_prefix(){
		return _("Restoring");
	}
}