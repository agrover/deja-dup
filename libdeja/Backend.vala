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

public abstract class Backend : Object
{
  public Settings settings {get; construct;}

  public signal void envp_ready(bool success, List<string>? envp, string? error = null);
  public signal void pause_op(string? header, string? msg);

  public MountOperation mount_op {get; set;}

  public abstract bool is_native(); // must be callable when nothing is mounted, nothing is prepared
  public virtual Icon? get_icon() {return null;}

  public abstract string get_location(ref bool as_root); // URI for duplicity
  public abstract string get_location_pretty(); // short description for user

  // list of what-provides hints
  public virtual string[] get_dependencies() {return {};}

  public virtual async bool is_ready(out string when) {when = null; return true;} // must be callable when nothing is mounted, nothing is prepared

  public virtual async void get_envp() throws Error {
    envp_ready(true, new List<string>());
  }

  public static uint64 INFINITE_SPACE = uint64.MAX;
  public virtual async uint64 get_space(bool free = true) {return INFINITE_SPACE;}
  
  // Arguments needed only when the particular mode is active
  // If mode == INVALID, arguments needed any time the backup is referenced.
  public virtual void add_argv(ToolJob.Mode mode, ref List<string> argv) {}
  
  public abstract Backend clone();

  public static Backend get_for_type(string backend_name, Settings? settings = null)
  {
    if (backend_name == "s3")
      return new BackendS3(settings);
    else if (backend_name == "gcs")
      return new BackendGCS(settings);
    else if (backend_name == "goa")
      return new BackendGOA(settings);
    else if (backend_name == "u1")
      return new BackendU1();
    else if (backend_name == "rackspace")
      return new BackendRackspace(settings);
    else if (backend_name == "openstack")
      return new BackendOpenstack(settings);
    else if (backend_name == "drive")
      return new BackendDrive(settings);
    else if (backend_name == "remote")
      return new BackendRemote(settings);
    else if (backend_name == "local")
      return new BackendLocal(settings);
    else
      return new BackendAuto();
  }

  public static string get_type_name(Settings settings)
  {
    var backend = settings.get_string(BACKEND_KEY);

    if (backend != "auto" &&
        backend != "s3" &&
        backend != "gcs" &&
        backend != "goa" &&
        backend != "u1" &&
        backend != "rackspace" &&
        backend != "openstack" &&
        backend != "drive" &&
        backend != "remote" &&
        backend != "local")
      backend = "auto"; // default to auto if string is not known

    return backend;
  }

  public static Backend get_default()
  {
    return get_for_type(get_default_type());
  }

  public static string get_default_type()
  {
    return get_type_name(get_settings());
  }
}

} // end namespace

