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

public const string U1_ROOT = "U1";
public const string U1_FOLDER_KEY = "folder";

class Listener : Object
{
  public delegate void Handler(string name, Variant args);
  public DBusProxy proxy {get; construct;}
  public string method {get; construct;}
  public Variant args {get; construct;}
  public unowned Handler handler {get; set;}

  public Listener(DBusProxy proxy, string method, Variant? args, Handler handler)
  {
    Object(proxy: proxy, method: method, args: args);
    this.handler = handler;
  }

  MainLoop loop;
  construct {
    loop = new MainLoop(null, false);
  }

  public void run()
  {
    Idle.add(() => {
      call_but_quit_on_fail.begin();
      return false;
    });
    proxy.g_signal.connect(handle_dbus_signal);
    loop.run();
    proxy.g_signal.disconnect(handle_dbus_signal);
  }

  async void call_but_quit_on_fail()
  {
    try {
      yield proxy.call(method, args, DBusCallFlags.NONE, -1, null);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      loop.quit();
    }
  }

  void handle_dbus_signal(DBusProxy obj, string? sender, string name, Variant args)
  {
    // Stop on first signal
    handler(name, args);
    loop.quit();
  }
}

class U1Checker : Checker
{
  PythonChecker pyu1;
  construct {
    try {
      var proxy = BackendU1.get_creds_proxy();
      if (proxy.get_name_owner() == null) {
        available = false;
        complete = true;
      }
    }
    catch (Error e) {
      warning("%s\n", e.message);
      available = false;
      complete = true;
    }

    if (!complete) {
      // A bit of abstraction leakage here; we have to keep these imports in
      // line with what duplicity uses.  Maybe we should add to duplicity a way
      // to ask 'can I use this backend?'
      pyu1 = PythonChecker.get_checker("ubuntuone.platform.credentials, ubuntuone.couch.auth");
      if (pyu1.complete) {
        available = pyu1.available;
        complete = pyu1.complete;
      }
      else {
        pyu1.notify["complete"].connect(() => {
          available = pyu1.available;
          complete = pyu1.complete;
          pyu1 = null;
        });
      }
    }
  }
}

public class BackendU1 : Backend
{
  ulong button_handler = 0;

  static Checker checker_instance = null;
  public static Checker get_checker()
  {
    if (checker_instance == null)
      checker_instance = new U1Checker();
    return checker_instance;
  }

  public override Backend clone() {
    return new BackendU1();
  }

  ~BackendU1()
  {
    if (button_handler > 0) {
      mount_op.disconnect(button_handler);
      button_handler = 0;
    }
  }

  public override bool is_native() {
    return false;
  }

  public override bool space_can_be_infinite() {
    return false;
  }

  public override Icon? get_icon() {
    return new ThemedIcon.from_names({"ubuntuone", "ubuntuone-installer", "deja-dup-cloud"});
  }

  public override async bool is_ready(out string when) {
    when = _("Backup will begin when a network connection becomes available.");
    return yield Network.get().can_reach ("https://one.ubuntu.com/");
  }

  public override string get_location(ref bool as_root)
  {
    // The UI backend for duplicity needs to talk to our session dbus, but it
    // can't as root.
    as_root = false;

    var settings = get_settings(U1_ROOT);
    var folder = get_folder_key(settings, U1_FOLDER_KEY);
    return "u1+http://%s".printf(folder);
  }

  public override string get_location_pretty()
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

    if (obj.get_name_owner() == null)
      return INFINITE_SPACE;

    uint64 total = INFINITE_SPACE;
    uint64 used = 0;
    var listener = new Listener(obj, "account_info", null, (name, args) => {
      if (name == "AccountInfoReady") {
        VariantIter iter;
        args.get("(a{ss})", out iter);
        string key, val;
        while (iter.next("{ss}", out key, out val)) {
          if (key == "quota_total")
            total = uint64.parse(val);
          else if (key == "quota_used")
            used = uint64.parse(val);
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
    if (obj.get_name_owner() == null) {
      ask_password();
      return;
    }

    var listener = new Listener(obj, "find_credentials", null, (name, args) => {
      if (name == "CredentialsFound")
        found = true;
    });
    listener.run();

    if (found)
      envp_ready(true, null);
    else
      ask_password();
  }

  void button_clicked()
  {
    sign_in.begin();
  }

  void ask_password() {
    mount_op.set("label_title", _("Connect to Ubuntu One"));
    mount_op.set("label_button", _("Sign into Ubuntu One…"));
    if (button_handler == 0)
      button_handler = Signal.connect_swapped(mount_op, "button-clicked",
                                              (Callback)button_clicked, this);
    mount_op.ask_password("", "", "", 0);
  }

  async void sign_in()
  {
    try {
      var obj = get_creds_proxy();
      if (obj.get_name_owner() == null) {
        envp_ready(false, null);
        return;
      }

      var listener = new Listener(obj, "login", new Variant("(a{ss})", null),
                                  (name, args) => {
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

  public static DBusProxy get_creds_proxy() throws Error
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

  public static DBusProxy get_prefs_proxy() throws Error
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

