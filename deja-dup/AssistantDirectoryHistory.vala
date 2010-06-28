using GLib;
using Gee;

public class DeletedFile {
		public string name {get; set;}
		public Time deleted {get; set;}
		public bool restore {get; set; default = false;}

		public DeletedFile(string name, Time deleted) {
			this.name = name;
			this.deleted = deleted;
		}

		public string filename() {
			var splited_fn = this.name.split("/");
			stdout.printf("filename: %s\n", splited_fn[splited_fn.length-1]);
			//return this.name.split("/")[-1];
			//return this.name;
			return splited_fn[splited_fn.length-1];
		}

		public string queue_format() {
			var file = this.name;
			var time = this.deleted.format("%s");
			return @"$file $time";
		}
}

public class AssistantDirectoryHistory : AssistantOperation {
	private File list_directory;

	private bool backups_queue_filled = false;
	private static int compare_time(Time a, Time b) {
		/*
		 * Compare function for backups queue
		 *
		 * Default comparing for queue goes from oldest to newest so we use our own
		 * compare function to reverse that ordering and proceed from newest to oldest
		 * since it is far more likely that user deleted file in near past.
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
	Gtk.Label current_scan_date = new Gtk.Label("");
	Gtk.Spinner spinner = new Gtk.Spinner();
	
	/* Confirmation page related widgets */
	Gtk.Label label;
	Gtk.Table restore_files_table;
	/*
		Gtk.Table in Glade needs to be set at least to 1 at start. When we update
		our table we start from 0 because we first resize table.
	 */
	int restore_files_table_rows = 0;
	
	public AssistantDirectoryHistory(File list_dir) {
			list_directory = list_dir;
	}

	private ArrayList<string>? files_in_directory() {
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

	[CCode (instance_pos = -1)]
	public void on_restoretoggle(Gtk.CellRendererToggle checkbox, int path) {
		checkbox.set_active(true);
	}

	Gtk.Widget? make_listfiles_page() {
			var page = new Gtk.Table(1, 1, false);
			page.name = "listfiles_page";
			var builder = new Gtk.Builder();
			try {
				builder.add_from_file("interface/listfiles-crt-out.ui");
				builder.connect_signals(this);
				
				var window = builder.get_object("viewport") as Gtk.Widget;
					//var treeview = builder.get_object("treeview") as Gtk.TreeView;
				var filelistwindow = builder.get_object("filelistwindow") as Gtk.ScrolledWindow;
				var status_table = builder.get_object("backup_table") as Gtk.Table;
				var progress_table = builder.get_object("progress_table") as Gtk.Table;

				/* Add backup and scan information */
				/* Backup source */
				Gtk.Widget w = new DejaDup.ConfigLabelLocation();
				status_table.attach(w, 1, 2, 0, 1, Gtk.AttachOptions.FILL, 0, 0, 0);

				/* Spinner */
				this.spinner.start();
				progress_table.attach(this.spinner, 1, 2, 0, 1, Gtk.AttachOptions.FILL, 0, 0, 0);

				/* Current date of scan */
				progress_table.attach(this.current_scan_date, 2, 3, 0, 1, Gtk.AttachOptions.FILL, 0, 0, 0);
				
				this.listmodel = new Gtk.ListStore (3, typeof (bool), typeof (string), typeof (string));
				var treeview = new Gtk.TreeView.with_model (this.listmodel);
				//treeview.set_model(this.listmodel);

				var toggle = new Gtk.CellRendererToggle();
				toggle.toggled.connect ((toggle, path) => {
					stdout.printf("%s\n",this.file_status[path.to_int()].name);
					
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
	
	void add_listfiles_page() {
		var page = make_listfiles_page();
		append_page(page);
		set_page_title(page, _("Deleted Files"));
		listfiles_page = page;
		//selectfiles_page = page;
	}

	/*void add_restorefiles_page() {
		var page = make_restorefiles_page();
		append_page(page);
		set_page_title(page, _("About to restore"));
		//selectfiles_page = page;
	}*/

	protected override void do_prepare(Assistant assist, Gtk.Widget page) {
		stdout.printf("do_prepare");
		base.do_prepare(assist, page);

		if (page == listfiles_page) {
			stdout.printf("listfiles_page");
			do_query_collection_dates();
			if (op != null && op.needs_password){
				provide_password();
			}
			//do_query();
		}
		else if (page == confirm_page) {
			stdout.printf("\nconfirm page\n");
			
			foreach(var delfile in this.file_status) {
				if (delfile.restore)
				{
					stdout.printf("OFFERING: %s\n\n", delfile.name);
					//stdout.printf("number of relevent rows: %u", this.restore_files_table.nrows);
					//this.restore_queue.push_tail(delfile.queue_format());
					this.restore_queue.offer(delfile);
					stdout.printf("rowz: %u\n", this.restore_files_table.nrows);
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
			this.backups_queue.clear();
		}
	}

	protected void handle_listed_files(DejaDup.OperationFiles op, string date, string file) {
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
		stdout.printf("\nhandle collection_dates\n");
    TimeVal tv = TimeVal();

		if (!this.backups_queue_filled) {
			//foreach(string date in dates){
			for(var i=dates.length()-1;i > 0;i--){
				if (tv.from_iso8601(dates.nth(i).data)) {
					Time t = Time.local(tv.tv_sec);
					stdout.printf("time of backup: d: %s, tse: %s, cd: %s\n", dates.nth(i).data, t.format("%s"), t.format("%c"));
					this.backups_queue.offer(t);
				}
			}
		}

		this.allfiles_prev = files_in_directory();
		this.backups_queue_filled = true;
		do_query_files_at_date();
	}

	protected void do_query_collection_dates() {
		stdout.printf("\ndo_query_collection_dates\n");
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
			stdout.printf("query_collection_dates start\n");
      query_op_collection_dates.start();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      show_error(e.message, null); // not really user-friendly text, but ideally this won't happen
      query_collection_dates_finished(query_op_collection_dates, false, false);
    }
	}
		
	protected void do_query_files_at_date(){			
		Time etime = backups_queue.poll();

		/* Update progress */
		this.current_scan_date.set_text(etime.format("%c"));
		
		stdout.printf("ADH do query, at epoch time: %s\n", etime.format("%c"));
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
    this.op_state = op.get_state();
    //this.query_op_files = null;
		this.query_op_collection_dates = null;
    this.op = null;
    
    if (cancelled)
      //do_close();
			stdout.printf("fail\n");
    else if (success)
      //go_forward();
			stdout.printf("success\n");
	}

	protected void query_wrapup() {
		stdout.printf("\nQUERY WRAPUP\n");
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

	protected override void apply_finished(DejaDup.Operation op, bool success, bool cancelled)
  {
    //status_icon = null; PRIV PARAMETER - FIXIT!
    this.op = null;

    if (cancelled) {
      if (success) // stop (resume later) vs cancel
        Gtk.main_quit();
      else
        do_close();
    }
    else {
      if (success) {
        succeeded = true;
				stdout.printf("restore queue size: %u", this.restore_queue.size);
				stdout.printf("what to restore: %s\n", this.restore_queue.peek().name);
				if (this.restore_queue.size > 0) {
					stdout.printf("apply finished v ADH; we need more restoring!");
					base.do_apply();
				} else {
					stdout.printf("no more files to restore");
					go_to_page(summary_page);
				}
      }
      else // show error
        force_visible(false);
    }
  }
	
	protected void query_files_finished(DejaDup.Operation op, bool success, bool cancelled)
  {
		this.op_state = op.get_state();
    this.query_op_files = null;
		//this.query_op_collection_dates = null;
    this.op = null;
		
		if (backups_queue.size == 0) {
			this.spinner.stop();
			this.spinner.destroy();
			this.current_scan_date.set_text("Done!");
		}
		else {
			do_query_files_at_date();
		}
    
    if (cancelled)
      //do_close();
			stdout.printf("fail\n");
    else if (success)
      //go_forward();
			stdout.printf("success\n");
  }

	protected override Gtk.Widget? make_confirm_page(){
		var page = new Gtk.Table(1, 1, false);
		page.name = "confirm_page";
		var builder = new Gtk.Builder();
		try {
			//builder.add_from_file("interface/restorefiles.glade");
			builder.add_from_file("interface/directory_history_summary.glade");
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

	/*protected override DejaDup.Operation create_op() {
		realize();
		stdout.printf("create_op");
		var xid = Gdk.x11_drawable_get_xid(this.window);
		return new DejaDup.OperationFiles((uint)xid);
	}*/
	protected override DejaDup.Operation create_op()
  {
		stdout.printf("create_op\n");
    realize();
    var xid = Gdk.x11_drawable_get_xid(this.window);
		/*	var rest_op = new DejaDup.OperationRestore(restore_location, date,
                                               restore_files, (uint)xid);*/

		stdout.printf("resture queue before length: %x\n", this.restore_queue.size);

		var restore_file = this.restore_queue.poll();
		stdout.printf("resture queue before after: %x\n", this.restore_queue.size);
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
		return _("Directory history");
	}
}