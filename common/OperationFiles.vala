using GLib;

namespace DejaDup {

public class OperationFiles : Operation {
	public OperationFiles(uint xid = 0) {
		stdout.printf("meh meh init");
		Object(xid: xid, mode: Mode.FILEHISTORY);
	}

	protected override List<string>? make_argv() throws Error
	{
			var homedir = new List<string>();
			stdout.printf("bzeeee make argv");
			return homedir;
	}

	public override void start() throws Error
  {
		stdout.printf("starting");
		base.start();
  }
}
}