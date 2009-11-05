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

public const string FILE_TYPE_KEY = "/apps/deja-dup/file/type";
public const string FILE_PATH_KEY = "/apps/deja-dup/file/path";
public const string FILE_UUID_KEY = "/apps/deja-dup/file/uuid";
public const string FILE_NAME_KEY = "/apps/deja-dup/file/name";

public class BackendFile : Backend
{
  public override Backend clone() {
    return new BackendFile();
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
    if (DuplicityInfo.get_default().has_native_gio)
      return file.get_uri();
    else {
      if (file.get_path() == null)
        throw new BackupError.BAD_CONFIG(_("GVFS FUSE is not installed"));
      return "file://" + file.get_path();
    }
  }

  public override string? get_location_pretty() throws Error
  {
    return get_location_from_gconf();
  }
  
  public override bool is_native() {
    try {
      var path = get_location_from_gconf();
      if (path != null) {
        var file = File.parse_name(path);
        return file.is_native();
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }

    return true; // default to yes?
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
    
    if (mode == Operation.Mode.INVALID && DuplicityInfo.get_default().has_native_gio)
      argv.prepend("--gio");
  }
  
  void fill_mount_info(File file)
  {
    try {
    }
    catch (Error e) {
    }
  }

  // This doesn't *really* worry about envp, it just is a convenient point to
  // hook into the operation steps to mount the file.
  public override async void get_envp() throws Error
  {
    var path = get_location_from_gconf();
    var file = File.parse_name(path);
    try {
      yield mount_file(file);
    }
    catch (Error e) {
      envp_ready(false, new List<string>(), e.message);
    }
  }
  
  async void mount_file(File file) throws Error
  {
    this.ref();

    var success = true;
    var client = get_gconf_client();
    var type = client.get_string(FILE_TYPE_KEY);
    if (type == "volume")
      success = yield mount_volume(file);
    else if (!file.is_native())
      success = yield mount_remote(file);

    if (success)
      fill_mount_info(file);
    envp_ready(success, new List<string>());

    this.unref();
  }

  async bool mount_remote(File file) throws Error
  {
    try {
      // Check if it's already mounted
      var mount = yield file.find_enclosing_mount_async(Priority.DEFAULT, null);
      if (mount != null)
        return true;
    }
    catch (Error e) {}

    return yield file.mount_enclosing_volume(MountMountFlags.NONE, mount_op, null);
  }

  async bool mount_volume(File file) throws Error
  {
    var client = get_gconf_client();
    var uuid = client.get_string(FILE_UUID_KEY);
    print("getting vol: %s\n", uuid);

    var vol = yield wait_for_volume(uuid);

    var mount = vol.get_mount();
    if (mount != null)
      return true;

    var loop = new MainLoop(null, false);
    var rv = false;

    print("volume: %s\n", vol.get_name());

    vol.mount(MountMountFlags.NONE, mount_op, null, (o, r) => {
      loop.quit();
      rv = ((Volume)o).mount_finish(r);
    });
    loop.run();
    return rv;
  }

  async Volume wait_for_volume(string uuid) throws Error
  {
    // For some reason, when I last tested this (glib 2.22.2), Volume.get_uuid
    // always returned null.
    // Looping and asking for the identifier is more reliable.
    var mon = VolumeMonitor.get();
    unowned List<Volume> vols = mon.get_volumes();
    Volume vol = null;
    foreach (Volume v in vols) {
      if (v.get_identifier(VOLUME_IDENTIFIER_KIND_UUID) == uuid) {
        vol = v;
        break;
      }
    }

    if (vol == null) {
      var name = client.get_string(FILE_NAME_KEY);
      print("Backup location not available.  Waiting for ‘%s’ to become connected…\n", name);
      var loop = new MainLoop(null, false);
      mon.volume_added.connect((m, v) => {
        loop.quit();
      });
      loop.run();
      return yield wait_for_volume(uuid);
    }

    return vol;
  }
}

} // end namespace

