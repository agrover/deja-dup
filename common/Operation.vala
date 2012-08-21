/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    For copyright information, see AUTHORS.

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

namespace DejaDup {

public abstract class Operation : Object
{
  /**
   * Abstract class that abstracts low level operations of duplicity
   * with specific classes for specific operations
   *
   * Abstract class that defines methods and properties that have to be defined
   * by classes that abstract operations from duplicity. It is generally unnecessary
   * but it is provided to provide easier development and an abstraction layer
   * in case Deja Dup project ever replaces its backend.
   */
  public signal void done(bool success, bool cancelled, string? detail);
  public signal void raise_error(string errstr, string? detail);
  public signal void action_desc_changed(string action);
  public signal void action_file_changed(File file, bool actual);
  public signal void progress(double percent);
  public signal void passphrase_required();
  public signal void question(string title, string msg);
  public signal void is_full(bool first);

  public bool use_cached_password {get; protected set; default = true;}
  public bool needs_password {get; set;}
  public Backend backend {get; private set;}
  public bool use_progress {get {return (job.flags & ToolJob.Flags.NO_PROGRESS) == 0;}
                            set {
                              if (value)
                                job.flags = job.flags | ToolJob.Flags.NO_PROGRESS;
                              else
                                job.flags = job.flags ^ ToolJob.Flags.NO_PROGRESS;
                            }}

  public ToolJob.Mode mode {get; construct; default = ToolJob.Mode.INVALID;}
  
  public static string mode_to_string(ToolJob.Mode mode)
  {
    switch (mode) {
    case ToolJob.Mode.BACKUP:
      return _("Backing up…");
    case ToolJob.Mode.RESTORE:
      return _("Restoring…");
    case ToolJob.Mode.STATUS:
      return _("Checking for backups…");
    case ToolJob.Mode.LIST:
      return _("Listing files…");
    default:
      return _("Preparing…");
    }
  }
  
  // The State functions can be used to carry information from one operation
  // to another.
  public class State {
    public Backend backend;
    public string passphrase;
  }
  public State get_state() {
    var rv = new State();
    rv.backend = backend;
    rv.passphrase = passphrase;
    return rv;
  }
  public void set_state(State state) {
    backend = state.backend;
    set_passphrase(state.passphrase);
  }

  SimpleSettings settings;
  internal ToolJob job;
  protected string passphrase;
  bool finished = false;
  string saved_detail = null;
  Operation chained_op = null;
  construct
  {
    backend = Backend.get_default();
  }

  public async virtual void start(bool try_claim_bus = true)
  {
    action_desc_changed(_("Preparing…"));  
    
    try {
      if (try_claim_bus)
        claim_bus();
    }
    catch (Error e) {
      raise_error(e.message, null);
      done(false, false, null);
      return;
    }

    yield DejaDup.Network.ensure_status();

    if (backend is BackendAuto) {
      // OK, we're not ready yet.  Let's hold off until we are
      settings = get_settings();
      settings.notify["backend"].connect(restart);
    }
    else
      restart();
  }

  void restart()
  {
    if (settings != null) {
      settings.notify["backend"].disconnect(restart);
      settings = null;
    }

    if (job != null) {
      SignalHandler.disconnect_matched(job, SignalMatchType.DATA,
                                       0, 0, null, null, this);
      job.stop();
      job = null;
    }

    try {
      job = make_tool_job();
    }
    catch (Error e) {
      raise_error(e.message, null);
      done(false, false, null);
      return;
    }

    job.mode = mode;
    job.backend = backend;

    make_argv();
    connect_to_job();

    ref(); // don't know what might happen in passphrase_required call

    // Get encryption passphrase if needed
    if (needs_password && passphrase == null) {
      needs_password = true;
      passphrase_required(); // will block and call set_passphrase when ready
    }
    else
      job.encrypt_password = passphrase;

    if (!finished)
      job.start();

    unref();
  }

  public void cancel()
  {
    if (chained_op != null)
      chained_op.cancel();
    else
      job.cancel();
  }
  
  public void stop()
  {
    if (chained_op != null)
      chained_op.stop();
    else
      job.stop();
  }
  
  protected virtual void connect_to_job()
  {
    /*
     * Connect Deja Dup to signals
     */
    job.done.connect((d, o, c, detail) => {operation_finished.begin(d, o, c, detail);});
    job.raise_error.connect((d, s, detail) => {raise_error(s, detail);});
    job.action_desc_changed.connect((d, s) => {action_desc_changed(s);});
    job.action_file_changed.connect((d, f, b) => {send_action_file_changed(f, b);});
    job.progress.connect((d, p) => {progress(p);});
    job.question.connect((d, t, m) => {question(t, m);});
    job.is_full.connect((first) => {is_full(first);});
    job.bad_encryption_password.connect(() => {
      // If tool gives us a gpg error, we set needs_password so that
      // we will prompt for it.
      needs_password = true;
      passphrase = null;
      restart();
    });
  }

  protected virtual void send_action_file_changed(File file, bool actual)
  {
    action_file_changed(file, actual);
  }

  public void set_passphrase(string? passphrase)
  {
    needs_password = false;
    this.passphrase = passphrase;
    if (job != null)
      job.encrypt_password = passphrase;
  }

  internal async virtual void operation_finished(ToolJob job, bool success, bool cancelled, string? detail)
  {
    finished = true;

    unclaim_bus();

    done(success, cancelled, detail);
  }
  
  protected virtual List<string>? make_argv()
  {
  /**
   * Abstract method that prepares arguments that will be sent to duplicity
   *
   * Abstract method that will prepare arguments that will be sent to duplicity
   * and return a list of those arguments.
   */
    return null;
  }

  static string combine_details(string? old_detail, string? new_detail)
  {
    if (old_detail == null)
      return new_detail;
    else if (new_detail == null)
      return old_detail;
    else
      return old_detail + "\n\n" + new_detail;
  }

  protected async void chain_op(Operation subop, string desc, string? detail)
  {
    /**
     * Sometimes an operation wants to chain to a separate operation.
     * Here is the glue to make that happen.
     */
    assert(chained_op == null);

    chained_op = subop;
    subop.done.connect((s, c, d) => {
      done(s, c, combine_details(saved_detail, d));
      chained_op = null;
    });
    subop.raise_error.connect((e, d) => {raise_error(e, d);});
    subop.progress.connect((p) => {progress(p);});
    subop.passphrase_required.connect(() => {
      needs_password = true;
      passphrase_required();
      if (!needs_password)
        subop.set_passphrase(passphrase);
    });
    subop.question.connect((t, m) => {question(t, m);});

    use_cached_password = subop.use_cached_password;
    saved_detail = combine_details(saved_detail, detail);
    subop.set_state(get_state());

    action_desc_changed(desc);
    progress(0);

    yield subop.start(false);
  }

  uint bus_id = 0;
  void claim_bus() throws BackupError
  {
    bool rv = false;
    var loop = new MainLoop();
    bus_id = Bus.own_name(BusType.SESSION, "org.gnome.DejaDup.Operation",
                          BusNameOwnerFlags.NONE, ()=>{},
                          ()=>{rv = true; loop.quit();},
                          ()=>{rv = false; loop.quit();});
    loop.run();
    if (bus_id == 0 || rv == false)
      throw new BackupError.ALREADY_RUNNING(_("Another backup operation is already running"));
  }

  void unclaim_bus()
  {
    if (bus_id > 0)
      Bus.unown_name(bus_id);
  }
}

} // end namespace

