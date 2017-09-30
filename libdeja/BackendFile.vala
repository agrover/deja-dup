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

public abstract class BackendFile : Backend
{
  public override string[] get_dependencies()
  {
    return Config.GVFS_PACKAGES.split(",");
  }

  // Get mountable root
  protected abstract File? get_root_from_settings();

  // Get full URI to backup folder
  protected abstract File? get_file_from_settings();

  // Location will be mounted by this time
  public override string get_location(ref bool as_root)
  {
    var file = get_file_from_settings();
    if (file == null)
      return "invalid://"; // shouldn't happen!

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
      // a good idea anyway.
      // 
      // Here's a joke for reading this far: Where did Napolean keep his armies?
      // In his sleevies!
      as_root = false;
    }

    return "gio+" + file.get_uri();
  }

  public override string get_location_pretty()
  {
    var file = get_file_from_settings();
    if (file == null)
      return "";
    return get_file_desc(file);
  }

  public override bool is_native() {
    return true;
  }

  // will be mounted by this time
  public override void add_argv(ToolJob.Mode mode, ref List<string> argv)
  {
    if (mode == ToolJob.Mode.BACKUP) {
      var file = get_file_from_settings();
      if (file != null && file.is_native())
        argv.prepend("--exclude=%s".printf(file.get_path()));
    }
  }

  // This doesn't *really* worry about envp, it just is a convenient point to
  // hook into the operation steps to mount the file.
  public override async void get_envp() throws Error
  {
    this.ref();
    try {
      yield do_mount();
    }
    catch (Error e) {
      envp_ready(false, new List<string>(), e.message);
    }
    this.unref();
  }

  async bool query_exists_async(File file)
  {
    try {
      yield file.query_info_async(FileAttribute.STANDARD_TYPE,
                                  FileQueryInfoFlags.NONE,
                                  Priority.DEFAULT, null);
      return true;
    }
    catch (Error e) {
      return false;
    }
  }

  async void do_mount() throws Error
  {
    yield mount();

    var gfile = get_file_from_settings();

    // Ensure directory exists (we check first rather than just doing it,
    // because this makes some backends -- like google-drive: -- work better,
    // as they allow multiple files with the same name. Querying it
    // anchors the path to the backend object and we don't create a second
    // copy this way.
    if (gfile != null && !(yield query_exists_async(gfile))) {
      try {
        gfile.make_directory_with_parents (null);
      }
      catch (IOError.EXISTS err2) {
        // ignore
      }
    }

    envp_ready(true, new List<string>());
  }

  protected virtual async void mount() throws Error {}

  public override async uint64 get_space(bool free = true)
  {
    var attr = free ? FileAttribute.FILESYSTEM_FREE : FileAttribute.FILESYSTEM_SIZE;
    try {
      var file = get_file_from_settings();
      if (file == null)
        return INFINITE_SPACE;
      var info = yield file.query_filesystem_info_async(attr, Priority.DEFAULT, null);
      if (!info.has_attribute(attr))
        return INFINITE_SPACE;
      var space = info.get_attribute_uint64(attr);
      if (in_testing_mode() && free &&
          Environment.get_variable("DEJA_DUP_TEST_SPACE_FREE") != null) {
          var free_str = Environment.get_variable("DEJA_DUP_TEST_SPACE_FREE");
          var free_list = free_str.split(";");
          space = uint64.parse(free_list[0]);
          if (free_list[1] != null)
            Environment.set_variable("DEJA_DUP_TEST_SPACE_FREE", string.joinv(";", free_list[1:free_list.length]), true);
      }
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

