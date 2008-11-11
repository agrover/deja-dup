/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008 Michael Terry <mike@mterry.name>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using GLib;

public abstract class Operation : Object
{
  public signal void done(bool success);
  
  protected Duplicity dup;
  protected Backend backend;
  string passphrase;
  construct
  {
    dup = new Duplicity();
    backend = Backend.get_default();
  }
  
  public void start() throws Error
  {
    if (backend == null) {
      done(false);
      return;
    }
    
    dup.done += operation_finished;
    List<string> argv = make_argv();
    if (argv == null)
      return;
    string[]? envp = backend.get_envp();
    if (envp == null)
      return;
    
    // Get encryption passphrase if needed
    var client = GConf.Client.get_default();
    if (client.get_bool(ENCRYPT_KEY)) {
      string[] real_envp = new string[envp.length + 1];
      
      if (!get_passphrase())
        return;
      real_envp[0] = "PASSPHRASE=%s".printf(passphrase);
      for (int i = 0; i < envp.length; ++i)
        real_envp[i + 1] = envp[i];
      dup.start(argv, real_envp);
    }
    else
      dup.start(argv, envp);
  }
  
  protected virtual void operation_finished(Duplicity dup, bool success, bool cancelled)
  {
    done(success);
  }
  
  protected abstract List<string>? make_argv() throws Error;
  
  void found_passphrase(GnomeKeyring.Result result, string? str)
  {
    if (result == GnomeKeyring.Result.OK)
      passphrase = str;
    Gtk.main_quit();
  }
  
  bool get_passphrase()
  {
    passphrase = null;
    
    // First, try user's keyring
    GnomeKeyring.find_password(PASSPHRASE_SCHEMA,
                               found_passphrase, null,
                               "owner", Config.PACKAGE,
                               "type", "passphrase");
    Gtk.main();
    
    if (passphrase != null)
      return true;
    
    // Ask user
    var dlg = new Gnome.PasswordDialog(_("Encryption Password"),
                                       _("Enter the password used to encrypt your backup files."),
                                       "", "", false);
    dlg.transient_parent = toplevel;
    dlg.show_remember = true;
    dlg.show_username = false;
    if (!dlg.run_and_block())
      return false;
    
    passphrase = dlg.get_password();
    
    // Save it
    var remember = dlg.get_remember();
    if (remember != Gnome.PasswordDialogRemember.NOTHING) {
      string where = remember == Gnome.PasswordDialogRemember.SESSION ?
                                 "session" : GnomeKeyring.DEFAULT;
      GnomeKeyring.store_password(PASSPHRASE_SCHEMA,
                                  where,
                                  _("Déjà Dup backup passphrase"),
                                  passphrase, null, null,
                                  "owner", Config.PACKAGE,
                                  "type", "passphrase");
    }
    
    return true;
  }
}

