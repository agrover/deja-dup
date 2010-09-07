/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008,2009 Michael Terry <mike@mterry.name>

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
  public signal void done(bool success, bool cancelled);
  public signal void raise_error(string errstr, string? detail);
  public signal void action_desc_changed(string action);
  public signal void action_file_changed(File file, bool actual);
  public signal void progress(double percent);
  public signal void passphrase_required();
  public signal void question(string title, string msg);
  public signal void secondary_desc_changed(string msg);
  
  public uint xid {get; construct;}
  public bool needs_password {get; private set;}
  public Backend backend {get; private set;}
  
  public enum Mode {
    INVALID,
    BACKUP,
    RESTORE,
    STATUS,
    LIST,
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
    passphrase = state.passphrase;
  }

  protected Duplicity dup;
  protected string passphrase;
  construct
  {
    dup = new Duplicity(mode);

    try {
      backend = Backend.get_default();
    }
    catch (Error e) {
      warning("%s\n", e.message);    
    }
  }
  
  public async virtual void start() throws Error
  {
    action_desc_changed(_("Preparing…"));

    if (backend == null) {
      done(false, false);
      return;
    }
    
    connect_to_dup();
    
    claim_bus();
    yield set_session_inhibited(true);
    
    // Get encryption passphrase if needed
    var client = get_gconf_client();
    if (client.get_bool(ENCRYPT_KEY) && passphrase == null) {
      needs_password = true;
      passphrase_required(); // will call continue_with_passphrase when ready
    }
    else
      continue_with_passphrase(passphrase);
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
    dup.done.connect((d, o, c) => {operation_finished(d, o, c);});
    dup.raise_error.connect((d, s, detail) => {raise_error(s, detail);});
    dup.action_desc_changed.connect((d, s) => {action_desc_changed(s);});
    dup.action_file_changed.connect((d, f, b) => {action_file_changed(f, b);});
    dup.progress.connect((d, p) => {progress(p);});
    dup.question.connect((d, t, m) => {question(t, m);});
    dup.secondary_desc_changed.connect((d, t) => {secondary_desc_changed(t);});
    backend.envp_ready.connect(continue_with_envp);
  }
  
  public async void continue_with_passphrase(string? passphrase)
  {
    needs_password = false;
    this.passphrase = passphrase;
    try {
      yield backend.get_envp();
    }
    catch (Error e) {
      raise_error(e.message, null);
      done(false, false);
    }
  }
  
  void continue_with_envp(DejaDup.Backend b, bool success, List<string>? envp, string? error) {
    if (!success) {
      if (error != null)
        raise_error(error, null);
      done(false, false);
      return;
    }
    
    bool encrypted = (passphrase != null && passphrase != "");
    if (encrypted)
      envp.append("PASSPHRASE=%s".printf(passphrase));
    else
      envp.append("PASSPHRASE="); // duplicity sometimes asks for a passphrase when it doesn't need it (during cleanup), so this stops it from prompting the user and us getting an exception as a result
      
    try {
      List<string> argv = make_argv();
      backend.add_argv(mode, ref argv);
      
      dup.start(backend, encrypted, argv, envp);
    }
    catch (Error e) {
      raise_error(e.message, null);
      done(false, false);
      return;
    }
  }
  
  protected async virtual void operation_finished(Duplicity dup, bool success, bool cancelled)
  {
    yield set_session_inhibited(false);
    unclaim_bus();
    
    if (success && passphrase == "") {
      // User entered no password.  Turn off encryption
      try {
        var client = GConf.Client.get_default();
        client.set_bool(ENCRYPT_KEY, false);
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    }
    
    done(success, cancelled);
  }
  
  protected virtual List<string>? make_argv() throws Error
  {
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
      throw new BackupError.ALREADY_RUNNING(_("Another Déjà Dup is already running"));
  }

  void unclaim_bus()
  {
    Bus.unown_name(bus_id);
  }
  
  uint inhibit_cookie = 0;
  async void set_session_inhibited(bool inhibit)
  {
    // Don't inhibit if we can resume safely
    if (DuplicityInfo.get_default().can_resume)
      return;

    try {
      // FIXME: use async version when I figure out the syntax
      DBusProxy obj = new DBusProxy.for_bus_sync(BusType.SESSION,
                                                 DBusProxyFlags.NONE, null, 
                                                 "org.gnome.SessionManager",
                                                 "/org/gnome/SessionManager",
                                                 "org.gnome.SessionManager",
                                                 null);
      
      if (inhibit) {
        if (inhibit_cookie > 0)
          return; // already inhibited
        
        var cookie_val = yield obj.call("Inhibit",
                                        // logout and suspend, but not switch user
                                        new Variant("(susu)",
                                                    Config.PACKAGE,
                                                    xid,
                                                    mode_to_string(dup.mode),
                                                    (uint) (1 | 4)),
                                        DBusCallFlags.NONE, -1, null);
        cookie_val.get("(u)", out inhibit_cookie);
      }
      else if (inhibit_cookie > 0) {
        yield obj.call("Uninhibit", new Variant("(u)", inhibit_cookie),
                       DBusCallFlags.NONE, -1, null);
        inhibit_cookie = 0;
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
}

} // end namespace

