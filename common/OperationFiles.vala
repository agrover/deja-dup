using GLib;

namespace DejaDup {

public class OperationFiles : Operation {
	public signal void listed_current_files(string date, string file);
	public Time time {public get; public set;}
	public File source {get; construct;}
		
	public OperationFiles(uint xid = 0,
	    									Time time_in,
	    									File source_in) {
		Object(xid: xid, mode: Mode.LIST, source: source_in);
		this.time = time_in;
	}

	protected override void connect_to_dup()
  {
    dup.listed_current_files.connect((d, date, file) => {listed_current_files(date, file);});
    base.connect_to_dup();
  }

	protected override List<string>? make_argv() throws Error
	{
    	List<string> argv = new List<string>();
    	//if (time != null) - no need, we don't allow null anyway
      argv.append("--time=%s".printf(time.format("%s")));

			dup.local = source;
			
			return argv;
	}

	public override void start() throws Error
  {
		//stdout.printf("operation files.start() with epoch time %s\n", time.format("%c"));
		stdout.printf("operation files start()\n");
		base.start();
  }

	protected override void operation_finished(Duplicity dup, bool success, bool cancelled)
	{
		base.operation_finished(dup, success, cancelled);
	}
}
}