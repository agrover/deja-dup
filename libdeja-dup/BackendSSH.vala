/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008—2009 Michael Terry <mike@mterry.name>

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

namespace DejaDup {

public const string SSH_USERNAME_KEY = "/apps/deja-dup/ssh/username";
public const string SSH_SERVER_KEY = "/apps/deja-dup/ssh/server";
public const string SSH_PORT_KEY = "/apps/deja-dup/ssh/port";
public const string SSH_DIRECTORY_KEY = "/apps/deja-dup/ssh/directory";

public class BackendSSH : Backend
{
  public BackendSSH(Gtk.Window? win) {
    toplevel = win;
  }
  
  public override Backend clone() {
    return new BackendSSH(toplevel);
  }
  
  public override void add_argv(ref List<string> argv) {
    argv.append("--ssh-askpass");
    argv.append("--ssh-options=-oStrictHostKeyChecking=no");
  }
  
  int get_port() throws Error
  {
    var client = GConf.Client.get_default();
    var port = client.get_int(SSH_PORT_KEY);
    return port > 0 ? port : 22;
  }
  
  string get_username() throws Error
  {
    var client = GConf.Client.get_default();
    var username = client.get_string(SSH_USERNAME_KEY);
    if (username == null || username == "")
      throw new BackupError.BAD_CONFIG(_("No username specified"));
    return username;
  }
  
  string get_server() throws Error
  {
    var client = GConf.Client.get_default();
    var server = client.get_string(SSH_SERVER_KEY);
    if (server == null || server == "")
      throw new BackupError.BAD_CONFIG(_("No server specified"));
    return server;
  }
  
  string get_directory() throws Error
  {
    var client = GConf.Client.get_default();
    var directory = client.get_string(SSH_DIRECTORY_KEY);
    if (directory == null || directory == "")
      return "/";
    else if (directory[0] != '/')
      return "/" + directory;
    else
      return directory;
  }
  
  public override string? get_location() throws Error
  {
    var username = get_username();
    var directory = get_directory();
    
    if (server == null) {
      // we haven't yet got server or port from gconf
      server = get_server();
      port = get_port();
    }
    
    return "ssh://%s@%s:%d/%s".printf(username, server, port, directory);
  }
  
  public override string? get_location_pretty() throws Error
  {
    var username = get_username();
    var directory = get_directory();
    
    if (server == null) {
      // we haven't yet got server or port from gconf
      server = get_server();
      port = get_port();
    }
    
    return _("%s on ssh://%s@%s:%d").printf(directory, username, server, port);
  }
  
  string gconf_id;
  string id;
  string server;
  int port;
  string secret_key;
  public override void get_envp() throws Error
  {
    var client = GConf.Client.get_default();
    gconf_id = client.get_string(SSH_USERNAME_KEY);
    id = gconf_id == null ? "" : gconf_id;
    
    server = get_server();
    port = get_port();
    
    if (id != "" && secret_key != null) {
      // We've already been run before and got the key
      got_secret_key();
      return;
    }
    
    if (id != "") {
      // First, try user's keyring
      secret_key = null;
      GnomeKeyring.find_network_password(id, null, server, null, "ssh",
                                         null, port, found_password);
    }
    else
      need_password();
  }
  
  void found_password(GnomeKeyring.Result result, GLib.List? list)
  {
    if (result == GnomeKeyring.Result.OK && list != null) {
      secret_key = ((GnomeKeyring.NetworkPasswordData)list.data).password;
      got_secret_key();
    }
    else {
      need_password();
    }
  }
  
  void save_password_callback(GnomeKeyring.Result result, uint32 val)
  {
  }
  
  public override void ask_password() {
    // Ask user
    var dlg = new Gnome.PasswordDialog(_("SSH Password"),
                                       _("Enter your SSH username and password for server %s.").printf(server),
                                       id, "", false);
    dlg.transient_parent = toplevel;
    dlg.show_remember = true;
    if (!dlg.run_and_block()) {
      envp_ready(false, new List<string>());
      return;
    }
    
    id = dlg.get_username();
    secret_key = dlg.get_password();
    
    // Save it
    var remember = dlg.get_remember();
    if (remember != Gnome.PasswordDialogRemember.NOTHING) {
      string where = remember == Gnome.PasswordDialogRemember.SESSION ?
                                 "session" : GnomeKeyring.DEFAULT;
      GnomeKeyring.set_network_password(where, id, null, server, null,
                                        "ssh", null, port, secret_key,
                                        save_password_callback);
    }
    
    got_secret_key();
  }
  
  void got_secret_key() {
    var client = GConf.Client.get_default();
    if (id != gconf_id) {
      try {
        client.set_string(SSH_USERNAME_KEY, id);
      }
      catch (Error e) {warning("%s\n", e.message);}
    }
    
    List<string> envp = new List<string>();
    envp.append("FTP_PASSWORD=%s".printf(secret_key));
    envp_ready(true, envp);
  }
}

} // end namespace

