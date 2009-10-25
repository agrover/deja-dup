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
  
  public Gtk.Window toplevel {get; construct;}
  public uint uppermost_xid {get; construct;}
  public bool needs_password {get; private set;}
  
  public enum Mode {
    INVALID,
    BACKUP,
    RESTORE,
    STATUS,
  }
  public Mode mode {get; construct; default = Mode.INVALID;}
  
  public static string mode_to_string(Mode mode)
  {
    switch (mode) {
    case Operation.Mode.BACKUP:
      return _("Backing up...");
    case Operation.Mode.RESTORE:
      return _("Restoring...");
    case Operation.Mode.STATUS:
      return _("Checking for backups...");
    default:
      return "";
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
  protected Backend backend;
  protected string passphrase;
  construct
  {
    dup = new Duplicity(mode, toplevel);

    try {
      backend = Backend.get_default(toplevel);
    }
    catch (Error e) {
      warning("%s\n", e.message);    
    }
  }
  
  public virtual void start() throws Error
  {
    action_desc_changed(_("Preparing..."));

    if (backend == null) {
      done(false, false);
      return;
    }
    
    connect_to_dup();
    
    if (!claim_bus(true)) {
      done(false, false);
      return;
    }
    set_session_inhibited(true);
    
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
    dup.done.connect(operation_finished);
    dup.raise_error.connect((d, s, detail) => {raise_error(s, detail);});
    dup.action_desc_changed.connect((d, s) => {action_desc_changed(s);});
    dup.action_file_changed.connect((d, f, b) => {action_file_changed(f, b);});
    dup.progress.connect((d, p) => {progress(p);});
    dup.question.connect((d, t, m) => {question(t, m);});
    dup.secondary_desc_changed.connect((d, t) => {secondary_desc_changed(t);});
    backend.envp_ready.connect(continue_with_envp);
  }
  
  public void continue_with_passphrase(string? passphrase)
  {
    needs_password = false;
    this.passphrase = passphrase;
    try {
      backend.get_envp();
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
  
  protected virtual void operation_finished(Duplicity dup, bool success, bool cancelled)
  {
    set_session_inhibited(false);
    claim_bus(false);
    
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
  
  bool claim_bus(bool claimed)
  {
    bool rv = set_bus_claimed("operation", claimed);
    if (claimed && !rv)
      raise_error(_("Another Déjà Dup is already running"), null);
    return rv;
  }
  
  uint inhibit_cookie = 0;
  void set_session_inhibited(bool inhibit)
  {
    // Don't inhibit if we can resume safely
    if (DuplicityInfo.get_default().can_resume)
      return;

    try {
      var conn = DBus.Bus.@get(DBus.BusType.SESSION);
      
      dynamic DBus.Object obj = conn.get_object ("org.gnome.SessionManager",
                                                 "/org/gnome/SessionManager",
                                                 "org.gnome.SessionManager");
      
      if (inhibit) {
        if (inhibit_cookie > 0)
          return; // already inhibited
        
        uint xid = uppermost_xid;
        if (xid == 0 && toplevel != null) {
          toplevel.realize();
          xid = Gdk.x11_drawable_get_xid(toplevel.window);
        }
        
        obj.Inhibit(Config.PACKAGE,
                    xid,
                    mode_to_string(dup.mode),
                    (uint) (1 | 4), // logout and suspend, but not switch user
                    out inhibit_cookie);
      }
      else if (inhibit_cookie > 0) {
        obj.Uninhibit(inhibit_cookie);
        inhibit_cookie = 0;
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
}

} // end namespace

