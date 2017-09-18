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
  public signal void install(string[] names, string[] ids);
  public signal void is_full(bool first);

  public bool use_cached_password {get; protected set; default = true;}
  public bool needs_password {get; set;}
  public Backend backend {get; protected set;}
  public bool use_progress {get; set; default = true;}

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

  internal ToolJob job;
  protected string passphrase;
  bool finished = false;
  string saved_detail = null;
  Operation chained_op = null;

  public async virtual void start()
  {
    action_desc_changed(_("Preparing…"));  

    yield check_dependencies();
    if (!finished) // might have been cancelled during check above
      restart();
  }

  void restart()
  {
    if (job != null) {
      SignalHandler.disconnect_matched(job, SignalMatchType.DATA,
                                       0, 0, null, null, this);
      job.stop();
      job = null;
    }

    try {
      job = DejaDup.get_tool().create_job();
    }
    catch (Error e) {
      raise_error(e.message, null);
      done(false, false, null);
      return;
    }

    job.mode = mode;
    job.backend = backend;
    if (!use_progress)
      job.flags |= ToolJob.Flags.NO_PROGRESS;

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
    else if (job != null)
      job.cancel();
    else
      operation_finished.begin(false, true, null);
  }
  
  public void stop()
  {
    if (chained_op != null)
      chained_op.stop();
    else if (job != null)
      job.stop();
    else
      operation_finished.begin(true, true, null);
  }
  
  protected virtual void connect_to_job()
  {
    /*
     * Connect Deja Dup to signals
     */
    job.done.connect((d, o, c, detail) => {operation_finished.begin(o, c, detail);});
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

  internal async virtual void operation_finished(bool success, bool cancelled, string? detail)
  {
    finished = true;

    yield DejaDup.clean_tempdirs();

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
    subop.install.connect((p, i) => {install(p, i);});

    use_cached_password = subop.use_cached_password;
    saved_detail = combine_details(saved_detail, detail);
    subop.set_state(get_state());

    action_desc_changed(desc);
    progress(0);

    yield subop.start();
  }

#if HAS_PACKAGEKIT
  async Pk.Results? get_pk_results(Pk.Client client, Pk.Bitfield bitfield, string[] pkgs)
  {
    Pk.Results results;
    try {
      results = yield client.resolve_async(bitfield, pkgs, null, () => {});
      if (results == null || results.get_error_code() != null)
        return null;
    } catch (IOError.NOT_FOUND e) {
      // This happens when the packagekit daemon isn't running -- it can't find the socket
      return null;
    } catch (Pk.ControlError e) {
      // This can happen when the packagekit daemon isn't installed or can't start(?)
      return null;
    } catch (Error e) {
      raise_error("%s".printf(e.message), null);
      done(false, false, null);
      return null;
    }

    return results;
  }
#endif

  // Returns true if we're all set, false if we should wait for install
  async void check_dependencies()
  {
#if HAS_PACKAGEKIT
    var deps = backend.get_dependencies();
    foreach (string dep in DejaDup.get_tool().get_dependencies())
      deps += dep;

    var client = new Pk.Client();

    // Check which deps have any version installed
    var bitfield = Pk.Bitfield.from_enums(Pk.Filter.INSTALLED, Pk.Filter.ARCH);
    Pk.Results results = yield get_pk_results(client, bitfield, deps);
    if (results == null)
      return;

    // Convert that to a set
    var installed = new GenericSet<string>(str_hash, str_equal);
    var package_array = results.get_package_array();
    for (var i = 0; i < package_array.length; i++) {
      installed.add(package_array.data[i].get_name());
    }

    // Now see which packages we actually have to bother installing
    string[] uninstalled = {};
    foreach (string pkg in deps) {
      if (!installed.contains(pkg))
        uninstalled += pkg;
    }
    if (uninstalled.length == 0)
      return;

    // Now get the list of uninstalled (we do both passes, because if there is
    // an update for a package, the new version can be returned here, even if
    // there is an older version installed -- NEWEST or NOT_NEWEST does not
    // affect this behavior).
    bitfield = Pk.Bitfield.from_enums(Pk.Filter.NOT_INSTALLED, Pk.Filter.ARCH, Pk.Filter.NEWEST);
    results = yield get_pk_results(client, bitfield, uninstalled);
    if (results == null)
      return;

    // Convert from List to arrays
    package_array = results.get_package_array();
    var package_ids = new string[0];
    var package_names = new string[0];
    for (var i = 0; i < package_array.length; i++) {
      package_names += package_array.data[i].get_name();
      package_ids += package_array.data[i].get_id();
    }

    if (package_names.length > 0)
      install(package_names, package_ids); // will block
#endif
  }
}

} // end namespace

