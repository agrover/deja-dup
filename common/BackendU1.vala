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

class Listener : Object
{
  public delegate void Handler(string name, Variant args);
  public DBusProxy proxy {get; construct;}
  public string method {get; construct;}
  public Handler handler {get; set;}

  public Listener(DBusProxy proxy, string method, Handler handler)
  {
    Object(proxy: proxy, method: method);
    this.handler = handler;
  }

  MainLoop loop;
  construct {
    loop = new MainLoop(null, false);
  }

  public void run()
  {
    Idle.add(() => {
      call_but_quit_on_fail();
      return false;
    });
    proxy.g_signal.connect(handle_dbus_signal);
    loop.run();
    proxy.g_signal.disconnect(handle_dbus_signal);
  }

  async void call_but_quit_on_fail()
  {
    try {
      yield proxy.call(method, null, DBusCallFlags.NONE, -1, null);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      loop.quit();
    }
  }

  void handle_dbus_signal(DBusProxy obj, string sender, string name, Variant args)
  {
    // Stop on first signal
    handler(name, args);
    loop.quit();
  }
}

public class BackendU1 : Backend
{
  public static bool is_available()
  {
    if (!DuplicityInfo.get_default().has_u1)
      return false;

    try {
      var obj = get_creds_proxy();
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
    var settings = get_settings(U1_ROOT);
    var folder = get_folder_key(settings, U1_FOLDER_KEY);
    return "u1://%s".printf(folder);
  }

  public override string? get_location_pretty() throws Error
  {
    var settings = get_settings(U1_ROOT);
    var folder = get_folder_key(settings, U1_FOLDER_KEY);
    if (folder == "")
      return _("Ubuntu One");
    else
      // Translators: %s is a folder.
      return _("%s on Ubuntu One").printf(folder);
  }

  public override async uint64 get_space(bool free = true)
  {
    DBusProxy obj = null;
    try {
      obj = get_prefs_proxy();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return INFINITE_SPACE;
    }

    uint64 total = INFINITE_SPACE;
    uint64 used = 0;
    var listener = new Listener(obj, "account_info", (name, args) => {
      if (name == "AccountInfoReady") {
        VariantIter iter;
        args.get("(a{ss})", out iter);
        string key, val;
        while (iter.next("{ss}", out key, out val)) {
          if (key == "quota_total")
            total = val.to_uint64();
          else if (key == "quota_used")
            used = val.to_uint64();
        }
      }
    });
    listener.run();

    if (free)
      return (total > used) ? (total - used) : 0;
    else
      return total;
  }

  public override async void get_envp() throws Error
  {
    bool found = false;
    var obj = get_creds_proxy();

    var listener = new Listener(obj, "find_credentials", (name, args) => {
      if (name == "CredentialsFound")
        found = true;
    });
    listener.run();

    if (found)
      envp_ready(true, null);
    else
      ask_password();
  }

  void ask_password() {
    mount_op.set("label_button", _("Sign into Ubuntu One…"));
    mount_op.connect("signal::button-clicked", sign_in, null);
    mount_op.ask_password(_("Connect to Ubuntu One"), "", "", 0);
  }

  async void sign_in()
  {
    try {
      var obj = get_creds_proxy();

      var listener = new Listener(obj, "register", (name, args) => {
        if (name == "CredentialsFound") {
          mount_op.set("go_forward", true);
          envp_ready(true, null);
        }
      });
      listener.run();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      envp_ready(false, null);
    }
  }

  static DBusProxy get_creds_proxy() throws Error
  {
    DBusProxy creds_proxy;
    creds_proxy = new DBusProxy.for_bus_sync(BusType.SESSION,
                                             DBusProxyFlags.NONE, null, 
                                             "com.ubuntuone.Credentials",
                                             "/credentials",
                                             "com.ubuntuone.CredentialsManagement",
                                             null);
    return creds_proxy;
  }

  static DBusProxy get_prefs_proxy() throws Error
  {
    DBusProxy prefs_proxy;
    prefs_proxy = new DBusProxy.for_bus_sync(BusType.SESSION,
                                             DBusProxyFlags.NONE, null, 
                                             "com.ubuntuone.controlpanel",
                                             "/preferences",
                                             "com.ubuntuone.controlpanel.Preferences",
                                             null);
    return prefs_proxy;
  }
}

} // end namespace

