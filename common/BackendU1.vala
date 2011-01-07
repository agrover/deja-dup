/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2010 Michael Terry <mike@mterry.name>

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

public const string U1_ROOT = "U1";
public const string U1_FOLDER_KEY = "folder";

public class BackendU1 : Backend
{
  public static bool is_available()
  {
    if (!DuplicityInfo.get_default().has_u1)
      return false;

    try {
      var obj = get_proxy();
      return obj.get_name_owner() != null;
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return false;
    }
  }

  public override Backend clone() {
    return new BackendU1();
  }

  public override bool is_native() {
    return false;
  }

  public override bool space_can_be_infinite() {
    return false;
  }

  public override Icon? get_icon() {
    return new ThemedIcon("ubuntuone");
  }

  public override bool is_ready(out string when) {
    when = _("Backup will begin when a network connection becomes available.");
    return Network.get().connected;
  }

  public override string? get_location() throws Error
  {
    return "http://example.com/";
  }

  public override string? get_location_pretty() throws Error
  {
    return _("Ubuntu One");
  }

  public override async void get_envp() throws Error
  {
    var obj = get_proxy();

    Idle.add(() => {
      obj.call("find_credentials", null, DBusCallFlags.NONE, -1, null);
      return false;
    });

    bool found = false;

    var loop = new MainLoop(null, false);
    obj.g_signal.connect((obj, sender, signal_name, args) => {
      if (signal_name == "CredentialsFound")
        found = true;
      loop.quit();
    });
    loop.run();

    if (found)
      envp_ready(true, null);
    else
      ask_password();
  }

  void ask_password() {
    mount_op.set("label_button", _("Sign into Ubuntu One"));
    mount_op.connect("signal::button-clicked", sign_in, null);
    mount_op.ask_password(_("Connect to Ubuntu One"), "", "", 0);
  }

  async void sign_in()
  {
    try {
      var obj = get_proxy();

      Idle.add(() => {
        obj.call("register", null, DBusCallFlags.NONE, -1, null);
        return false;
      });

      var loop = new MainLoop(null, false);
      obj.g_signal.connect((obj, sender, signal_name, args) => {
        if (signal_name == "CredentialsFound") {
          mount_op.set("go_forward", true);
          envp_ready(true, null);
        }
        loop.quit();
      });
      loop.run();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      envp_ready(false, null);
    }
  }

  static DBusProxy get_proxy() throws Error
  {
    return new DBusProxy.for_bus_sync(BusType.SESSION,
                                      DBusProxyFlags.NONE, null, 
                                      "com.ubuntuone.Credentials",
                                      "/credentials",
                                      "com.ubuntunone.CredentialsManagement",
                                      null);
  }
}

} // end namespace

