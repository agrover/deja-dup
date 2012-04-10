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

  public bool needs_password {get; set;}
  public Backend backend {get; private set;}
  public bool use_progress {get {return dup.use_progress;}
                            set {dup.use_progress = value;}}

  public enum Mode {
    /*
   * Mode of operation of instance
   *
   * Every instance of class that inherit its methods and properties from
   * this class must define in which mode it operates. Based on this Duplicity
   * attaches appropriate argument.
   */
    INVALID,
    BACKUP,
    RESTORE,
    STATUS,
    LIST,
    FILEHISTORY
  }
  public Mode mode {get; construct; default = Mode.INVALID;}
  
  public static string mode_to_string(Mode mode)
  {
    switch (mode) {
    case Operation.Mode.BACKUP:
      return _("Backing up…");
    case Operation.Mode.RESTORE:
      return _("Restoring…");
    case Operation.Mode.STATUS:
      return _("Checking for backups…");
    case Operation.Mode.LIST:
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
  internal Duplicity dup;
  protected string passphrase;
  bool finished = false;
  construct
  {
    backend = Backend.get_default();
  }

  public async virtual void start()
  {
    action_desc_changed(_("Preparing…"));  
    
    try {
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

    if (dup != null) {
      SignalHandler.disconnect_matched(dup, SignalMatchType.DATA,
                                       0, 0, null, null, this);
      dup.cancel();
      dup = null;
    }

    dup = new Duplicity(mode);

    connect_to_dup();

    ref(); // don't know what might happen in passphrase_required call

    // Get encryption passphrase if needed
    if (needs_password && passphrase == null) {
      needs_password = true;
      passphrase_required(); // will block and call set_passphrase when ready
    }
    else
      dup.encrypt_password = passphrase;

    if (!finished)
      continue_with_passphrase();

    unref();
  }

  public void cancel()
  {
    dup.cancel();
  }
  
  public void stop()
  {
    dup.stop();
  }
  
  protected virtual void connect_to_dup()
  {
    /*
     * Connect Deja Dup to signals
     */
    dup.done.connect((d, o, c, detail) => {operation_finished(d, o, c, detail);});
    dup.raise_error.connect((d, s, detail) => {raise_error(s, detail);});
    dup.action_desc_changed.connect((d, s) => {action_desc_changed(s);});
    dup.action_file_changed.connect((d, f, b) => {action_file_changed(f, b);});
    dup.progress.connect((d, p) => {progress(p);});
    dup.question.connect((d, t, m) => {question(t, m);});
    dup.is_full.connect((first) => {is_full(first);});
    dup.bad_encryption_password.connect(() => {
      // If duplicity gives us a gpg error, we set needs_password so that
      // we will prompt for it.
      needs_password = true;
      passphrase = null;
      restart();
    });
  }

  public void set_passphrase(string? passphrase)
  {
    needs_password = false;
    this.passphrase = passphrase;
    if (dup != null)
      dup.encrypt_password = passphrase;
  }

  async void continue_with_passphrase()
  {
   /*
    * Continues with operation after passphrase has been acquired.
    */
    try {
      backend.envp_ready.connect(continue_with_envp);
      yield backend.get_envp();
    }
    catch (Error e) {
      raise_error(e.message, null);
      operation_finished(dup, false, false, null);
    }
  }
  
  void continue_with_envp(DejaDup.Backend b, bool success, List<string>? envp, string? error)
  {
    /*
     * Starts Duplicity backup with added enviroment variables
     * 
     * Start Duplicity backup process with costum values for enviroment variables.
     */
    backend.envp_ready.disconnect(continue_with_envp);

    if (!success) {
      if (error != null)
        raise_error(error, null);
      operation_finished(dup, false, false, null);
      return;
    }

    try {
      List<string> argv = make_argv();
      backend.add_argv(mode, ref argv);
      
      dup.start(backend, argv, envp);
    }
    catch (Error e) {
      raise_error(e.message, null);
      operation_finished(dup, false, false, null);
      return;
    }
  }
  
  internal async virtual void operation_finished(Duplicity dup, bool success, bool cancelled, string? detail)
  {
    finished = true;

    unclaim_bus();

    done(success, cancelled, detail);
  }
  
  protected virtual List<string>? make_argv() throws Error
  {
  /**
   * Abstract method that prepares arguments that will be sent to duplicity
   *
   * Abstract method that will prepare arguments that will be sent to duplicity
   * and return a list of those arguments.
   */
    return null;
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
    Bus.unown_name(bus_id);
  }
}

} // end namespace

