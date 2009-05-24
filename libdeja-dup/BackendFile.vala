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

public const string FILE_PATH_KEY = "/apps/deja-dup/file/path";

public class BackendFile : Backend
{
  public BackendFile(Gtk.Window? win) {
    toplevel = win;
  }
  
  public override Backend clone() {
    return new BackendFile(toplevel);
  }
  
  string? get_location_from_gconf() throws Error
  {
    var client = get_gconf_client();
    var path = client.get_string(FILE_PATH_KEY);
    return path;
  }
  
  public override string? get_location() throws Error
  {
    var path = get_location_from_gconf();
    var file = File.parse_name(path);
    if (file.get_path() == null)
      throw new BackupError.BAD_CONFIG(_("GVFS FUSE is not installed"));
    return "file://" + file.get_path();
  }

  public override string? get_location_pretty() throws Error
  {
    return get_location_from_gconf();
  }
  
  public override void add_argv(Operation.Mode mode, ref List<string> argv)
  {
    if (mode == Operation.Mode.BACKUP) {
      try {
        var path = get_location_from_gconf();
        if (path != null) {
          var file = File.parse_name(path);
          if (file.is_native())
            argv.prepend("--exclude=%s".printf(file.get_path()));
        }
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    }
  }
  
  // This doesn't *really* worry about envp, it just is a convenient point to
  // hook into the operation steps to mount the file.
  public override void get_envp() throws Error
  {
    var path = get_location_from_gconf();
    var file = File.parse_name(path);
    Mount mount = null;
    if (!file.is_native()) {
      // Check if it's mounted
      try {
        mount = file.find_enclosing_mount(null);
      }
      catch (Error e) {}
      
      if (mount == null) {
        check_if_password_needed(file);
        return;
      }
    }
    
    envp_ready(true, new List<string>());
  }
  
  void check_if_password_needed(File file)
  {
    // disallow interaction
    file.mount_enclosing_volume(MountMountFlags.NONE, null, null, (o, r) => {
      try {
        var success = ((File)o).mount_enclosing_volume_finish(r);
        envp_ready(success, new List<string>());
      }
      catch (IOError.PERMISSION_DENIED e) {
        need_password();
        return;
      }
      catch (Error e) {
        envp_ready(false, new List<string>(), e.message);
      }
    });
  }
  
  public override void ask_password()
  {
    // Make sure it's mounted
    string path;
    try {
      path = get_location_from_gconf();
    }
    catch (Error e) {
      envp_ready(false, new List<string>(), e.message);
      return;
    }
    
    var file = File.parse_name(path);
    var op = hacks_mount_operation_new(toplevel);
    file.mount_enclosing_volume(MountMountFlags.NONE, op, null, (o, r) => {
      try {
        var success = ((File)o).mount_enclosing_volume_finish(r);
        envp_ready(success, new List<string>());
      }
      catch (Error e) {
        envp_ready(false, new List<string>(), e.message);
      }
    });
  }
}

} // end namespace

