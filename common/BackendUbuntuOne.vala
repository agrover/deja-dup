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

public class BackendUbuntuOne : Backend
{
  public static bool is_available()
  {
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
    return new BackendUbuntuOne();
  }

  public override bool is_native() {
    return false;
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
    print("about to call find_credentials\n");
    var builder = new VariantBuilder(new VariantType("a{ss}"));
    var creds = yield obj.call("find_credentials",
                               new Variant("(sa{ss})", "Ubuntu One", builder),
                               DBusCallFlags.NONE, -1, null);
    print("called find_credentials\n");
    if (false) // TODO
      envp_ready(true, null);
    else
      ask_password();
  }

  void ask_password() {
    mount_op.set("label_button", _("Sign into Ubuntu One"));
    mount_op.connect("signal::button-clicked", sign_in, null);
    //mount_op.reply.connect(got_password_reply);
    mount_op.ask_password(_("Connect to Ubuntu One"), "", "", 0);
  }

  async void sign_in()
  {
    try {
      var obj = get_proxy();
      print("signing in!\n");
      var builder = new VariantBuilder(new VariantType("a{ss}"));
      builder.add("{ss}", "tc_url", "https://one.ubuntu.com/terms/");
      builder.add("{ss}", "ping_url", "https://one.ubuntu.com/oauth/sso-finished-so-get-tokens/");
      builder.add("{ss}", "help_text", _("Ubuntu One requires an Ubuntu Single Sign On (SSO) account. This process will allow you to create a new account, if you do not yet have one."));
      var creds = yield obj.call("register",
                                 new Variant("(sa{ss})", "Ubuntu One", builder),
                                 DBusCallFlags.NONE, -1, null);
      print("done signing in\n");
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
                                      "com.ubuntu.sso",
                                      "/com/ubuntu/sso/credentials",
                                      "com.ubuntu.sso.CredentialsManagement",
                                      null);
  }
}

} // end namespace

