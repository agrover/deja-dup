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

public const string FILE_ROOT_KEY = "/apps/deja-dup/file";
public const string FILE_TYPE_KEY = "/apps/deja-dup/file/type";
public const string FILE_PATH_KEY = "/apps/deja-dup/file/path";
public const string FILE_RELPATH_KEY = "/apps/deja-dup/file/relpath";
public const string FILE_UUID_KEY = "/apps/deja-dup/file/uuid";
public const string FILE_NAME_KEY = "/apps/deja-dup/file/name";
public const string FILE_SHORT_NAME_KEY = "/apps/deja-dup/file/short-name";
public const string FILE_ICON_KEY = "/apps/deja-dup/file/icon";

public class BackendFile : Backend
{
  public override Backend clone() {
    return new BackendFile();
  }

  // Will return null if volume isn't ready
  static File? get_file_from_gconf() throws Error
  {
    var client = get_gconf_client();
    var type = client.get_string(FILE_TYPE_KEY);
    if (type == "volume") {
      var path = client.get_string(FILE_RELPATH_KEY);
      var uuid = client.get_string(FILE_UUID_KEY);
      var vol = find_volume_by_uuid(uuid);
      if (vol == null)
        return null;
      var mount = vol.get_mount();
      if (mount == null)
        return null;
      var root = mount.get_root();
      if (path != null)
        return root.get_child(path);
      else
        return root;
    }
    else {
      var path = client.get_string(FILE_PATH_KEY);
      return File.parse_name(path);
    }
  }

  // Location will be mounted by this time
  public override string? get_location() throws Error
  {
    var file = get_file_from_gconf();
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
    var client = get_gconf_client();
    var type = client.get_string(FILE_TYPE_KEY);
    if (type == "volume") {
      var path = client.get_string(FILE_RELPATH_KEY);
      var name = client.get_string(FILE_SHORT_NAME_KEY);
      // Translators: %2$s is the name of a removable drive, %1$s is a folder
      // on that removable drive.
      return _("%1$s on %2$s").printf(path, name);
    }
    else {
      var file = get_file_from_gconf();
      return get_file_desc(file);
    }
  }
  
  public override bool is_native() {
    try {
      var client = get_gconf_client();
      var type = client.get_string(FILE_TYPE_KEY);
      if (type == "volume")
        return true;

      var file = get_file_from_gconf();
      if (file != null)
        return file.is_native();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }

    return true; // default to yes?
  }

  public override bool is_ready(out string when) {
    when = null;
    try {
      var file = get_file_from_gconf();
      if (file == null) { // must be a volume that isn't yet mounted. See if volume is connected
        var uuid = client.get_string(FILE_UUID_KEY);
        var vol = find_volume_by_uuid(uuid);
        if (vol != null)
          return true;
        else {
          var client = get_gconf_client();
          var name = client.get_string(FILE_SHORT_NAME_KEY);
          when = _("Backup will begin when %s becomes connected.").printf(name);
          return false;
        }
      }
      else if (file.is_native())
        return true;
      else {
        when = _("Backup will begin when a network connection becomes available.");
        return NetworkManager.get().connected;
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }

    return true; // default to yes?
  }

  public override Icon? get_icon() {
    try {
      var client = get_gconf_client();
      var type = client.get_string(FILE_TYPE_KEY);
      if (type == "volume") {
        var icon_str = client.get_string(FILE_ICON_KEY);
        return Icon.new_for_string(icon_str);
      }
      else {
        var file = get_file_from_gconf();
        var info = file.query_info(FILE_ATTRIBUTE_STANDARD_ICON,
                                   FileQueryInfoFlags.NONE, null);
        return info.get_icon();
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return null;
    }
  }

  // will be mounted by this time
  public override void add_argv(Operation.Mode mode, ref List<string> argv)
  {
    if (mode == Operation.Mode.BACKUP) {
      try {
        var file = get_file_from_gconf();
        if (file != null && file.is_native())
          argv.prepend("--exclude=%s".printf(file.get_path()));
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    }
    
    if (mode == Operation.Mode.INVALID && DuplicityInfo.get_default().has_native_gio)
      argv.prepend("--gio");
  }
  
  // Checks if file is secretly a volume file and fills out gconf data if so.
  public async static void check_for_volume_info(File file) throws Error
  {
    var client = get_gconf_client();

    if (!file.is_native()) {
      client.set_string(FILE_TYPE_KEY, "normal");
      return;
    }

    if (!file.query_exists(null))
      return; // doesn't tell us anything

    Mount mount = null;
    try {
      mount = yield file.find_enclosing_mount_async(Priority.DEFAULT, null);
    }
    catch (Error e) {}
    if (mount == null) {
      client.set_string(FILE_TYPE_KEY, "normal");
      return;
    }

    var volume = mount.get_volume();
    if (volume == null)
      return;

    var uuid = volume.get_identifier(VOLUME_IDENTIFIER_KIND_UUID);
    if (uuid == null || uuid == "")
      return;

    var relpath = mount.get_root().get_relative_path(file);
    if (relpath == null)
      relpath = "";

    client.set_string(FILE_UUID_KEY, uuid);
    client.set_string(FILE_RELPATH_KEY, relpath);
    client.set_string(FILE_TYPE_KEY, "volume");

    update_volume_info(volume);
  }

  static void update_volume_info(Volume volume) throws Error
  {
    var client = get_gconf_client();

    var name = volume.get_name();
    if (name == null || name == "")
      return;
    var short_name = name;

    var drive = volume.get_drive();
    if (drive != null) {
      var drive_name = drive.get_name();
      if (drive_name != null && drive_name != "")
        name = "%s: %s".printf(drive_name, name);
    }

    var icon = volume.get_icon();
    string icon_str = null;
    if (icon != null)
      icon_str = icon.to_string();

    client.set_string(FILE_NAME_KEY, name);
    client.set_string(FILE_SHORT_NAME_KEY, short_name);
    client.set_string(FILE_ICON_KEY, icon_str);

    // Also update full path just in case (useful if downgrading to old version?)
    var mount = volume.get_mount();
    if (mount != null) {
      var path = client.get_string(FILE_RELPATH_KEY);
      if (path != null)
        path = mount.get_root().get_child(path).get_parse_name();
      client.set_string(FILE_PATH_KEY, path);
    }
  }

  // This doesn't *really* worry about envp, it just is a convenient point to
  // hook into the operation steps to mount the file.
  public override async void get_envp() throws Error
  {
    try {
      yield mount_file();
    }
    catch (Error e) {
      envp_ready(false, new List<string>(), e.message);
    }
  }
  
  async void mount_file() throws Error
  {
    this.ref();

    var success = true;
    var client = get_gconf_client();
    var type = client.get_string(FILE_TYPE_KEY);
    if (type == "volume")
      success = yield mount_volume();
    else if (type == "normal") {
      var file = get_file_from_gconf();
      if (!file.is_native())
        success = yield mount_remote();
    }

    // If we don't know what type this is, look up volume data
    if (type != "volume" && type != "normal" && success) {
      var gfile = get_file_from_gconf();
      yield check_for_volume_info(gfile);
    }

    envp_ready(success, new List<string>());

    this.unref();
  }

  async bool mount_remote() throws Error
  {
    var file = get_file_from_gconf();
    try {
      // Check if it's already mounted
      var mount = yield file.find_enclosing_mount_async(Priority.DEFAULT, null);
      if (mount != null)
        return true;
    }
    catch (Error e) {}

    return yield file.mount_enclosing_volume(MountMountFlags.NONE, mount_op, null);
  }

  async bool mount_volume() throws Error
  {
    var client = get_gconf_client();
    var uuid = client.get_string(FILE_UUID_KEY);

    var vol = yield wait_for_volume(uuid);

    var mount = vol.get_mount();
    if (mount != null) {
      update_volume_info(vol);
      return true;
    }

    var loop = new MainLoop(null, false);
    var rv = false;
    Error error = null;

    vol.mount(MountMountFlags.NONE, mount_op, null, (o, r) => {
      loop.quit();
      try {
        rv = ((Volume)o).mount_finish(r);
      }
      catch (Error e) {
        error = e;
      }
    });
    loop.run();

    if (rv)
      update_volume_info(vol);
    else
      throw error;

    return rv;
  }

  static Volume? find_volume_by_uuid(string uuid)
  {
    var mon = VolumeMonitor.get();
    mon.ref(); // bug 569418; bad things happen when VM goes away
    List<Volume> vols = mon.get_volumes();
    foreach (Volume v in vols) {
      // For some reason, when I last tested this (glib 2.22.2), 
      // Volume.get_uuid always returned null.
      // Looping and asking for the identifier is more reliable.
      if (v.get_identifier(VOLUME_IDENTIFIER_KIND_UUID) == uuid)
        return v;
    }
    return null;
  }

  async Volume wait_for_volume(string uuid) throws Error
  {
    var vol = find_volume_by_uuid(uuid);
    if (vol == null) {
      var name = client.get_string(FILE_NAME_KEY);
      pause_op(_("Backup location not available"), _("Waiting for ‘%s’ to become connected…").printf(name));
      var loop = new MainLoop(null, false);
      var mon = VolumeMonitor.get();
      mon.ref(); // bug 569418; bad things happen when VM goes away
      mon.volume_added.connect((m, v) => {
        loop.quit();
      });
      loop.run();
      return yield wait_for_volume(uuid);
    }

    return vol;
  }

  public override async uint64 get_space(bool free = true)
  {
    var attr = free ? FILE_ATTRIBUTE_FILESYSTEM_FREE : FILE_ATTRIBUTE_FILESYSTEM_SIZE;
    try {
      var file = get_file_from_gconf();
      var info = yield file.query_filesystem_info_async(attr, Priority.DEFAULT, null);
      var space = info.get_attribute_uint64(attr);
      if (space == INFINITE_SPACE)
        return space - 1; // avoid accidentally reporting infinite
      else
        return space;
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return INFINITE_SPACE;
    }
  }
}

} // end namespace

