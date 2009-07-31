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
  public signal void done(bool success);
  public signal void raise_error(string errstr, string? detail);
  public signal void action_desc_changed(string action);
  public signal void action_file_changed(File file);
  public signal void progress(double percent);
  public signal bool passphrase_required();
  public signal bool backend_password_required();
  
  public Gtk.Window toplevel {get; construct;}
  public uint uppermost_xid {get; construct;}
  
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
    
    // Default is to go ahead with password collection.  This will be
    // overridden by anyone else that connects to this signal.
    passphrase_required.connect((o) => {return true;});
    backend_password_required.connect((o) => {return true;});
  }
  
  public virtual void start() throws Error
  {
    if (backend == null) {
      done(false);
      return;
    }
    
    connect_to_dup();
    
    if (!claim_bus(true)) {
      done(false);
      return;
    }
    set_session_inhibited(true);
    
    // Get encryption passphrase if needed
    var client = get_gconf_client();
    if (client.get_bool(ENCRYPT_KEY) && passphrase == null)
      get_passphrase(); // will call continue_with_passphrase when ready
    else
      continue_with_passphrase();
  }
  
  public void cancel()
  {
    dup.cancel();
  }
  
  protected virtual void connect_to_dup()
  {
    dup.done.connect(operation_finished);
    dup.raise_error.connect((d, s, detail) => {raise_error(s, detail);});
    dup.action_desc_changed.connect((d, s) => {action_desc_changed(s);});
    dup.action_file_changed.connect((d, f) => {action_file_changed(f);});
    dup.progress.connect((d, p) => {progress(p);});
    backend.envp_ready.connect(continue_with_envp);
    backend.need_password.connect((b) => {
      bool can_ask_now = backend_password_required();
      if (can_ask_now)
        backend.ask_password();
    });
  }
  
  void continue_with_passphrase() throws Error
  {
    backend.get_envp();
  }
  
  void continue_with_envp(DejaDup.Backend b, bool success, List<string>? envp, string? error) {
    if (!success) {
      if (error != null)
        raise_error(error, null);
      done(false);
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
      done(false);
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
    
    done(success);
  }
  
  protected virtual List<string>? make_argv() throws Error
  {
    return null;
  }
  
  void found_passphrase(GnomeKeyring.Result result, string? str)
  {
    if (result == GnomeKeyring.Result.OK)
      passphrase = str;
    
    try {
      if (passphrase != null)
        continue_with_passphrase();
      else {
        bool can_ask_now = passphrase_required();
        if (can_ask_now)
          ask_passphrase();
        // else wait for consumer of Operation to call ask_passphrase
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  
  void get_passphrase()
  {
    // First, try user's keyring
    GnomeKeyring.find_password(PASSPHRASE_SCHEMA,
                               found_passphrase,
                               "owner", Config.PACKAGE,
                               "type", "passphrase");
  }
  
  void save_password_callback(GnomeKeyring.Result result)
  {
  }
  
  public void ask_passphrase() throws Error
  {
    // Ask user
    var dlg = new Gnome.PasswordDialog(_("Encryption Password"),
                                       _("Enter the password used to encrypt your backup files."),
                                       "", "", false);
    dlg.transient_parent = toplevel;
    dlg.show_remember = true;
    dlg.show_username = false;
    if (!dlg.run_and_block()) {
      done(false);
      return;
    }
    
    passphrase = dlg.get_password();
    passphrase = passphrase.strip();
    
    if (passphrase != "") {
      // Save it
      var remember = dlg.get_remember();
      if (remember != Gnome.PasswordDialogRemember.NOTHING) {
        string where = remember == Gnome.PasswordDialogRemember.SESSION ?
                                   "session" : GnomeKeyring.DEFAULT;
        GnomeKeyring.store_password(PASSPHRASE_SCHEMA,
                                    where,
                                    _("Déjà Dup backup passphrase"),
                                    passphrase, save_password_callback,
                                    "owner", Config.PACKAGE,
                                    "type", "passphrase");
      }
    }
    
    continue_with_passphrase();
  }
  
  public void ask_backend_password() throws Error
  {
    backend.ask_password();
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

