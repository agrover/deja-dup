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

public abstract class Backend : Object
{
  public signal void envp_ready(bool success, List<string>? envp, string? error = null);
  public signal void pause_op(string header, string msg);

  public MountOperation mount_op {get; set;}

  public abstract bool is_native();
  public virtual Icon? get_icon() {return null;}

  public abstract string? get_location() throws Error;
  public abstract string? get_location_pretty() throws Error; // short description for user

  public virtual async void get_envp() throws Error {
    envp_ready(true, new List<string>());
  }
  
  // Arguments needed only when the particular mode is active
  // If mode == INVALID, arguments needed any time the backup is referenced.
  public virtual void add_argv(Operation.Mode mode, ref List<string> argv) {}
  
  public abstract Backend clone();
  
  public static Backend? get_default() throws Error
  {
    var client = get_gconf_client();
    var backend_name = client.get_string(BACKEND_KEY);
    if (backend_name == "s3")
      return new BackendS3();
    else if (backend_name == "file")
      return new BackendFile();
    else
      return null;
  }
}

} // end namespace

