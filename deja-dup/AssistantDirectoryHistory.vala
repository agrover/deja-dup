using GLib;
using Gee;

public class AssistantDirectoryHistory : AssistantOperation {
	public AssistantDirectoryHistory() {
		stdout.printf("behehehe\n");
		//Object(automatic: automatic);
		//var xid = Gdk.x11_drawable_get_xid(this.window);

    //var query_op = new DejaDup.OperationStatus();
    //query_op.collection_dates.connect(handle_collection_dates);
		//var dup = new Duplicity(Operation.mode.CHECK_CONTENTS);
		//var xid = Gdk.x11_drawable_get_xid(this.window);
		//stdout.printf("xid: %s", xid);
		files_in_directory();
	}

	private int files_in_directory() {
		File directory = File.new_for_path("/home/urbans/");
		var file_list = new ArrayList<string> ();

		try {
			var enumerator = directory.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME, 0, null);
			FileInfo fileinfo;
			while ((fileinfo = enumerator.next_file(null)) != null){
				stdout.printf("%s\n",fileinfo.get_name());
				file_list.add(fileinfo.get_name());
			}
			return 0;
		} catch(Error e){
			stdout.printf("%s\n", e.message);
			return 1;
		}
	}

	[CCode (instance_pos = -1)]
	public void on_restorebutton_clicked(Gtk.Button source) {
		stdout.printf("muuuu!");
		source.label = "works!";
	}

	public Gtk.Widget make_listfiles_page() {
			//stdout.printf("mejk list filez");
			var page = new Gtk.Table(1, 1, false);
			var builder = new Gtk.Builder();
			builder.add_from_file("interface/listfiles.ui");
			builder.connect_signals(this);
    	var window = builder.get_object("viewport") as Gtk.Widget;
			window.reparent(page);
			return page;
	}

	void add_listfiles_page() {
		var page = make_listfiles_page();
		append_page(page);
		set_page_title(page, _("List Files"));
	
	}
		
	protected override void add_setup_pages() {
		add_listfiles_page();
	}

	protected override Gtk.Widget? make_confirm_page(){
		try {
			var page = new Gtk.Table(1, 2, false);
			var builder = new Gtk.Builder();
    	builder.add_from_file("/home/urbans/Documents/dev/deja-dup.nautilus/interface/sample2.ui");
    	//builder.connect_signals(assdirhist);
   		builder.connect_signals(null);
    	var window = builder.get_object("frame1") as Gtk.Widget;
			window.reparent(page);
			return page;
		} catch (Error e) {
			stderr.printf("ni ni interfejsa: %s\n", e.message);
			var page = new Gtk.Table(0, 2, false);
    	page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
			return page;
		}
	}
	protected override DejaDup.Operation create_op(){
		realize();
		stdout.printf("create_op");
		var xid = Gdk.x11_drawable_get_xid(this.window);
		return new DejaDup.OperationFiles((uint)xid);
	}
	protected override string get_progress_file_prefix(){
		return _("Directory history");
	}
	/*[CCode (instance_pos = -1)]
  public void on_button1_clicked (Gtk.Button source) {
		source.label = "Thank you!";
	}*/

	//[CCode (instance_pos = -1)]
	//public void on_button2_clicked (Gtk.Button source) {
	//	source.label = "Thanks!";
	//}
}

	//public string directory_location;
	
	//public AssistantDirectoryHistory() {
	//	stdout.printf("behehehe");		
	//}

	/*protected override string get_progress_file_prefix()
  {
    return _("Dir hist:");
  }

	protected override DejaDup.Operation create_op()
  {
    realize();
    var xid = Gdk.x11_drawable_get_xid(this.window);
    return new DejaDup.OperationBackup((uint)xid);
  }

	protected override Gtk.Widget? make_confirm_page()
  {
    
  }*/
//}