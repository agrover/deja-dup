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

public const string FILE_ROOT = "File";
public const string FILE_TYPE_KEY = "type";
public const string FILE_PATH_KEY = "path";
public const string FILE_RELPATH_KEY = "relpath";
public const string FILE_UUID_KEY = "uuid";
public const string FILE_NAME_KEY = "name";
public const string FILE_SHORT_NAME_KEY = "short-name";
public const string FILE_ICON_KEY = "icon";

public class BackendFile : Backend
{
  public override Backend clone() {
    return new BackendFile();
  }

  // Will return null if volume isn't ready
  static File? get_file_from_settings()
  {
    var settings = get_settings(FILE_ROOT);
    var type = settings.get_string(FILE_TYPE_KEY);
    if (type == "volume") {
      var path_val = settings.get_value(FILE_RELPATH_KEY);
      var path = path_val.get_bytestring();
      var uuid = settings.get_string(FILE_UUID_KEY);
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
      var path = settings.get_string(FILE_PATH_KEY);
      return File.parse_name(path);
    }
  }

  // Location will be mounted by this time
  public override string get_location(ref bool as_root)
  {
    var file = get_file_from_settings();

    if (as_root && !file.is_native()) {
      // OK...  Root can't use GVFS URIs as-is because it would need access to
      // our GVFS mounts which are only available on our session dbus.  Which
      // root can't talk to.  Possible workarounds:
      //  * Some magic to let root talk to our gvfs daemons (haven't found yet)
      //  * Use FUSE local paths (root also isn't given access to these mounts)
      //  * Have duplicity notice that it needs root to write to a file, and
      //    then restart itself under sudo.  But then we'd just hit the same
      //    problem again but now duplicity has to solve it...
      //  * Restore to a temporary folder and move files over with sudo.  This
      //    is what we used to always do in older deja-dup.  But it had
      //    several problems with consuming the hard drive, especially if the
      //    user had partitioned in ways we didn't expect.  Hard to know where
      //    a safe spot is to hoard all the files.
      //  * Pass mount username/password to duplicity as environment variables
      //    and have root do the mount itself.  This could work...  if we had
      //    a reliable way to get the username/password.  We could get it from
      //    keyring (even then, only a guess, since the daemon could have set
      //    the 'object' or 'authtype' fields, which we don't know if it did)
      //    or from a MountOperation.  But a user could have mounted it earlier
      //    in session without saving password in keyring.  And we can't force
      //    an unmount on the user just so we can remount it.
      //  * Have duplicity try to mount and ask user for password.  We'd need
      //    to add functionality to duplicity to allow a conversation between a
      //    driving app like deja-dup and itself, to be able to proxy these
      //    prompts and questions to the user.  This would work nicely, but is
      //    a very different interaction model than duplicity uses today.
      //    Much more deja-dup-focused.  If we're going down this direction,
      //    there are all sorts of two-way interactions that we could stand to
      //    benefit from.  Would require a deep rethink of our driving model.
      //
      // So in the absence of an actually good solution, we'll just disable
      // running under sudo if the location is remote.  :(  Maybe our
      // over-eager needs-root algorithm got it wrong anyway. Regardless, this
      // way the user will get a permissions denied error that will point them
      // in the direction of trying to restore in a new folder rather than on
      // top of their running system, which, let's be honest, is probably not
      // a good idea anyway.  BTW, where does Napolean keep his armies?
      // In his sleevies!
      as_root = false;
    }

    return file.get_uri();
  }

  public override string get_location_pretty()
  {
    var settings = get_settings(FILE_ROOT);
    var type = settings.get_string(FILE_TYPE_KEY);
    if (type == "volume") {
      var path_val = settings.get_value(FILE_RELPATH_KEY);
      var path = "";
      try {
        path = Filename.to_utf8(path_val.get_bytestring(), -1, null, null);
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
      var name = settings.get_string(FILE_SHORT_NAME_KEY);
      if (path == "")
        return name;
      else
        // Translators: %2$s is the name of a removable drive, %1$s is a folder
        // on that removable drive.
        return _("%1$s on %2$s").printf(path, name);
    }
    else {
      var file = get_file_from_settings();
      return get_file_desc(file);
    }
  }
  
  public override bool is_native() {
    var settings = get_settings(FILE_ROOT);
    var type = settings.get_string(FILE_TYPE_KEY);
    if (type == "volume")
      return true;

    var file = get_file_from_settings();
    if (file != null)
      return file.is_native();

    return true; // default to yes?
  }

  public override async bool is_ready(out string when) {
    when = null;

    var file = get_file_from_settings();
    if (file == null) { // must be a volume that isn't yet mounted. See if volume is connected
      var settings = get_settings(FILE_ROOT);
      var uuid = settings.get_string(FILE_UUID_KEY);
      var vol = find_volume_by_uuid(uuid);
      if (vol != null)
        return true;
      else {
        var name = settings.get_string(FILE_SHORT_NAME_KEY);
        when = _("Backup will begin when %s becomes connected.").printf(name);
        return false;
      }
    }
    else if (file.is_native())
      return true;
    else {
      when = _("Backup will begin when a network connection becomes available.");
      return yield Network.get().can_reach (file.get_uri ());
    }
  }

  public override Icon? get_icon() {
    var settings = get_settings(FILE_ROOT);
    var type = settings.get_string(FILE_TYPE_KEY);
    string icon_name = "folder-remote";
    if (type == "volume")
      icon_name = settings.get_string(FILE_ICON_KEY);
    else {
      File file = get_file_from_settings();
      if (file != null) {
        try {
          var info = file.query_info(FileAttribute.STANDARD_ICON,
                                     FileQueryInfoFlags.NONE, null);
          return info.get_icon();
        }
        catch (Error e) {
          if (file.is_native())
            icon_name = "folder";
        }
      }
    }

    try {
      return Icon.new_for_string(icon_name);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return null;
    }
  }

  // will be mounted by this time
  public override void add_argv(ToolJob.Mode mode, ref List<string> argv)
  {
    if (mode == ToolJob.Mode.BACKUP) {
      var file = get_file_from_settings();
      if (file != null && file.is_native())
        argv.prepend("--exclude=%s".printf(file.get_path()));
    }
    
    if (mode == ToolJob.Mode.INVALID)
      argv.prepend("--gio");
  }
  
  // Checks if file is secretly a volume file and fills out settings data if so.
  public async static void check_for_volume_info(File file) throws Error
  {
    var settings = get_settings(FILE_ROOT);

    if (!file.is_native()) {
      settings.set_string(FILE_TYPE_KEY, "normal");
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
      settings.set_string(FILE_TYPE_KEY, "normal");
      return;
    }

    var volume = mount.get_volume();
    if (volume == null)
      return;

    string relpath = null;
    if (file != null) {
      relpath = mount.get_root().get_relative_path(file);
      if (relpath == null)
        relpath = "";
    }

    yield set_volume_info(volume, relpath);
  }

  public async static void set_volume_info(Volume volume, string? relpath = null)
  {
    var uuid = volume.get_identifier(VolumeIdentifier.UUID);
    if (uuid == null || uuid == "")
      return;

    var settings = get_settings(FILE_ROOT);
    settings.delay();
    settings.set_string(FILE_TYPE_KEY, "volume");
    settings.set_string(FILE_UUID_KEY, uuid);
    if (relpath != null)
      settings.set_value(FILE_RELPATH_KEY, new Variant.bytestring(relpath));
    update_volume_info(volume);
    settings.apply();
  }

  static void update_volume_info(Volume volume)
  {
    var settings = get_settings(FILE_ROOT);

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

    settings.delay();

    settings.set_string(FILE_NAME_KEY, name);
    settings.set_string(FILE_SHORT_NAME_KEY, short_name);
    settings.set_string(FILE_ICON_KEY, icon_str);

    settings.apply();
  }

  // This doesn't *really* worry about envp, it just is a convenient point to
  // hook into the operation steps to mount the file.
  public override async void get_envp() throws Error
  {
    this.ref();
    try {
      yield mount_file();
    }
    catch (Error e) {
      envp_ready(false, new List<string>(), e.message);
    }
    this.unref();
  }
  
  bool is_being_mounted_error(Error e)
  {
    return e.message.has_prefix("DBus error org.gtk.Private.RemoteVolumeMonitor.Failed:");
  }

  async void delay(uint secs)
  {
    var loop = new MainLoop(null);
    Timeout.add_seconds(secs, () => {
      loop.quit();
      return false;
    });
    loop.run();
  }

  async void mount_file() throws Error
  {
    var success = true;
    var settings = get_settings(FILE_ROOT);
    var type = settings.get_string(FILE_TYPE_KEY);

    try {
      if (type == "volume")
        success = yield mount_volume();
      else if (type == "normal") {
        var file = get_file_from_settings();
        if (!file.is_native())
          success = yield mount_remote(file);
      }
    }
    catch (IOError.FAILED err) {
      // So, this is odd, and not very descriptive, but IOError.FAILED is the
      // error given when someone else is mounting at the same time.  Sometimes
      // happens when a USB stick is inserted and nautilus is fighting us.
      if (is_being_mounted_error(err)) {
        yield delay(1); // Try again in a second
        yield mount_file();
        return;
      }
      else
        throw err; // continue error on
    }

    if (success) {
      var gfile = get_file_from_settings();

      // If we don't know what type this is, look up volume data
      yield check_for_volume_info(gfile);

      // Ensure directory exists
      try {
        gfile.make_directory_with_parents (null);
      }
      catch (IOError.EXISTS err2) {
        // ignore
      }
    }

    envp_ready(success, new List<string>());
  }

  async bool mount_remote(File file) throws Error
  {
    if (!Network.get().connected) {
      pause_op(_("Backup location not available"),
               _("Waiting for a network connection…"));
      var loop = new MainLoop(null, false);
      var sigid = Network.get().notify["connected"].connect(() => {
        if (Network.get().connected)
          loop.quit();
      });
      loop.run();
      Network.get().disconnect(sigid);
      pause_op(null, null);
    }

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
    var settings = get_settings(FILE_ROOT);
    var uuid = settings.get_string(FILE_UUID_KEY);

    var vol = yield wait_for_volume(uuid);

    var mount = vol.get_mount();
    if (mount != null) {
      update_volume_info(vol);
      return true;
    }

    var rv = yield vol.mount(MountMountFlags.NONE, mount_op, null);
    if (rv)
      update_volume_info(vol);

    return rv;
  }

  public static Volume? find_volume_by_uuid(string uuid)
  {
    var mon = VolumeMonitor.get();
    mon.ref(); // bug 569418; bad things happen when VM goes away
    List<Volume> vols = mon.get_volumes();
    foreach (Volume v in vols) {
      // For some reason, when I last tested this (glib 2.22.2), 
      // Volume.get_uuid always returned null.
      // Looping and asking for the identifier is more reliable.
      if (v.get_identifier(VolumeIdentifier.UUID) == uuid)
        return v;
    }
    return null;
  }

  async Volume wait_for_volume(string uuid) throws Error
  {
    var vol = find_volume_by_uuid(uuid);
    if (vol == null) {
      var settings = get_settings(FILE_ROOT);
      var name = settings.get_string(FILE_NAME_KEY);
      pause_op(_("Backup location not available"), _("Waiting for ‘%s’ to become connected…").printf(name));
      var loop = new MainLoop(null, false);
      var mon = VolumeMonitor.get();
      mon.ref(); // bug 569418; bad things happen when VM goes away
      var sigid = mon.volume_added.connect((m, v) => {
        loop.quit();
      });
      loop.run();
      mon.disconnect(sigid);
      pause_op(null, null);
      return yield wait_for_volume(uuid);
    }

    return vol;
  }

  public override async uint64 get_space(bool free = true)
  {
    var attr = free ? FileAttribute.FILESYSTEM_FREE : FileAttribute.FILESYSTEM_SIZE;
    try {
      var file = get_file_from_settings();
      var info = yield file.query_filesystem_info_async(attr, Priority.DEFAULT, null);
      if (!info.has_attribute(attr))
        return INFINITE_SPACE;
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

  public override bool space_can_be_infinite() {return false;}
}

} // end namespace

