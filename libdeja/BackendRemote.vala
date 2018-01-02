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

public const string REMOTE_ROOT = "Remote";
public const string REMOTE_URI_KEY = "uri";
public const string REMOTE_FOLDER_KEY = "folder";

public class BackendRemote : BackendFile
{
  public BackendRemote(Settings? settings) {
    Object(settings: (settings != null ? settings : get_settings(REMOTE_ROOT)));
  }

  public override Backend clone() {
    return new BackendRemote(settings);
  }

  protected virtual string get_folder()
  {
    return get_folder_key(settings, REMOTE_FOLDER_KEY, true);
  }

  // Get mountable root
  protected override File? get_root_from_settings()
  {
    var uri = settings.get_string(REMOTE_URI_KEY);
    return File.parse_name(uri);
  }

  // Get full URI to backup folder
  protected override File? get_file_from_settings()
  {
    var root = get_root_from_settings();
    var folder = get_folder();

    // So ideally the user just put the server address ("sftp://example.org" or
    // "dav://example.org/remote.php/webdav/").  And then we add the folder on
    // top of whatever that location gives as the default location -- which
    // might be the user's home directory or whatever.
    //
    // However... the user might put more in the server address field (and we
    // ourselves might have migrated an old gsettings key into the address
    // field that had the full path as part of it). So if it looks like the
    // URI has more than the mount root in it, we add that together with the
    // folder value to make a new path from the mount root (not the default
    // location root).

    try {
      var mount = root.find_enclosing_mount(null);
      var mount_root = mount.get_root();

      // I've had inconsistent results from gvfs.  On davs://, sometimes
      // equal() isn't correct, but has_prefix() is.  On sftp://, sometimes
      // equal() is correct, but has_prefix() isn't.  We test both, hopefully
      // they both won't be wrong.  The point of this check is that we *should*
      // use default_location(), but won't if the user has added extra bits to
      // the URI for us.  Once GNOME bug 786217 is fixed for a while, we can
      // simply check if there is a relative path between the two.
      if (root.equal(mount_root) || !root.has_prefix(mount_root))
        root = mount.get_default_location();
    }
    catch (IOError.NOT_MOUNTED e) {
      // ignore
    }
    catch (Error e) {
      warning("%s", e.message);
    }

    try {
      return root.get_child_for_display_name(folder);
    }
    catch (Error e) {
      warning("%s", e.message);
    }

    // Really?!
    return root.get_child(folder);
  }

  public override bool is_native() {
    return false;
  }

  // Check if we should give nicer message
  string get_unready_message(File root, Error e)
  {
    // SMB likes to give back a very generic error when the host is not
    // available ("Invalid argument").  Try to work around that here.
    // TODO: file upstream bug.
    if (Posix.errno == Posix.EAGAIN &&
        root.get_uri_scheme() == "smb" &&
        e.matches(IOError.quark(), 0))
    {
      return _("The network server is not available");
    }

    return e.message;
  }

  public override async bool is_ready(out string when)
  {
    var root = get_root_from_settings();
    when = null;
    try {
      // Test if we can mount successfully (this is better than simply
      // testing if network is reachable, since ssh configs and all sorts of
      // things might be taken into account by GIO but not by a simple
      // network test). If we do end up mounting it, that's fine.  This is
      // only called right before attempting an operation.
      return yield root.mount_enclosing_volume(MountMountFlags.NONE, mount_op, null);
    } catch (IOError.ALREADY_MOUNTED e) {
      when = _("Backup will begin when a network connection becomes available.");
      return Network.get().connected;
    } catch (IOError.FAILED_HANDLED e) {
      // Needed user input, so we know we can reach server
      return true;
    } catch (Error e) {
      when = get_unready_message(root, e);
      return false;
    }
  }

  public override Icon? get_icon()
  {
    try {
      return Icon.new_for_string("network-server");
    }
    catch (Error e) {
      warning("%s", e.message);
      return null;
    }
  }

  protected override async void mount() throws Error
  {
    if (!Network.get().connected) {
      pause_op(_("Storage location not available"),
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

    var root = get_root_from_settings();

    if (root.get_uri_scheme() == "smb" && root.get_uri().split("/").length < 5) {
      // Special sanity check for some edge cases like smb:// where if the user
      // just puts in smb://server/ as the root, GIO thinks it's a valid root,
      // but the share never ends up mounted.
      throw new IOError.FAILED("%s", _("Samba network locations must include both a hostname and a share name."));
    }

    try {
      yield root.mount_enclosing_volume(MountMountFlags.NONE, mount_op, null);
    } catch (IOError.ALREADY_MOUNTED e) {
      return;
    } catch (Error e) {
      // try once more with same response in case we timed out while waiting for user
      mount_op.@set("retry_mode", true);
      yield root.mount_enclosing_volume(MountMountFlags.NONE, mount_op, null);
    } finally {
      mount_op.@set("retry_mode", false);
    }
  }
}

} // end namespace
