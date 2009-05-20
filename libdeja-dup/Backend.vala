/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
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

public abstract class Backend : Object
{
  public signal void envp_ready(bool success, List<string>? envp, string? error = null);
  public signal void need_password();
  
  public Gtk.Window toplevel {get; construct;}
  
  public abstract string? get_location() throws Error;
  public abstract string? get_location_pretty() throws Error; // short description for user
  
  public virtual void get_envp() throws Error {
    envp_ready(true, new List<string>());
  }
  
  // Arguments needed only when the particular mode is active
  // If mode == INVALID, arguments needed any time the backup is referenced.
  public virtual void add_argv(Operation.Mode mode, ref List<string> argv) {}
  
  public virtual void ask_password() {}
  
  public abstract Backend clone();
  
  public static Backend? get_default(Gtk.Window? win) throws Error
  {
    var client = get_gconf_client();
    var backend_name = client.get_string(BACKEND_KEY);
    if (backend_name == "s3")
      return new BackendS3(win);
    else if (backend_name == "file")
      return new BackendFile(win);
    else if (backend_name == "ssh")
      return new BackendSSH(win);
    else
      return null;
  }
}

} // end namespace

