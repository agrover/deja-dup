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

public const string RACKSPACE_ROOT = "Rackspace";
public const string RACKSPACE_USERNAME_KEY = "username";
public const string RACKSPACE_CONTAINER_KEY = "container";

const string RACKSPACE_SERVER = "auth.api.rackspacecloud.com";

public class BackendRackspace : Backend
{
  public static Checker get_checker() {
    return PythonChecker.get_checker("cloudfiles");
  }

  public override Backend clone() {
    return new BackendRackspace();
  }

  public override bool is_native() {
    return false;
  }

  public override Icon? get_icon() {
    return new ThemedIcon("deja-dup-cloud");
  }

  public override async bool is_ready(out string when) {
    when = _("Backup will begin when a network connection becomes available.");
    return yield Network.get().can_reach ("http://%s/".printf(RACKSPACE_SERVER));
  }

  public override string get_location(ref bool as_root)
  {
    var settings = get_settings(RACKSPACE_ROOT);
    var container = get_folder_key(settings, RACKSPACE_CONTAINER_KEY);
    if (container == "") {
      container = Environment.get_host_name();
      settings.set_string(RACKSPACE_CONTAINER_KEY, container);
    }
    return "cf+http://%s".printf(container);
  }

  public override string get_location_pretty()
  {
    var settings = get_settings(RACKSPACE_ROOT);
    var container = settings.get_string(RACKSPACE_CONTAINER_KEY);
    if (container == "")
      return _("Rackspace Cloud Files");
    else
      // Translators: %s is a folder.
      return _("%s on Rackspace Cloud Files").printf(container);
  }

  string settings_id;
  string id;
  string secret_key;
  public override async void get_envp() throws Error
  {
    var settings = get_settings(RACKSPACE_ROOT);
    settings_id = settings.get_string(RACKSPACE_USERNAME_KEY);
    id = settings_id == null ? "" : settings_id;

    if (id != "" && secret_key != null) {
      // We've already been run before and got the key
      got_secret_key();
      return;
    }

    if (id != "") {
      // First, try user's keyring
      secret_key = null;
      GnomeKeyring.find_network_password(id, null, RACKSPACE_SERVER, null, "https",
                                         null, 0, found_password);
    }
    else
      ask_password();
  }

  void found_password(GnomeKeyring.Result result,
                      GLib.List<GnomeKeyring.NetworkPasswordData>? list)
  {
    if (result == GnomeKeyring.Result.OK && list != null) {
      secret_key = list.data.password;
      got_secret_key();
    }
    else {
      ask_password();
    }
  }
  
  void save_password_callback(GnomeKeyring.Result result, uint32 val)
  {
  }
  
  void got_password_reply(MountOperation mount_op, MountOperationResult result)
  {
    if (result != MountOperationResult.HANDLED) {
      envp_ready(false, new List<string>(), _("Permission denied"));
      return;
    }

    id = mount_op.username;
    secret_key = mount_op.password;

    // Save it
    var remember = mount_op.password_save;
    if (remember != PasswordSave.NEVER) {
      string where = (remember == PasswordSave.FOR_SESSION) ?
                     "session" : GnomeKeyring.DEFAULT;
      GnomeKeyring.set_network_password(where, id, null, RACKSPACE_SERVER, null,
                                        "https", null, 0, secret_key,
                                        save_password_callback);
    }

    got_secret_key();
  }

  void ask_password() {
    mount_op.set("label_help", _("You can sign up for a Rackspace Cloud Files account <a href=\"%s\">online</a>.").printf("https://signup.rackspacecloud.com/signup"));
    mount_op.set("label_title", _("Connect to Rackspace Cloud Files"));
    mount_op.set("label_password", _("_API access key"));
    mount_op.set("label_show_password", _("S_how API access key"));
    mount_op.set("label_remember_password", _("_Remember API access key"));
    mount_op.reply.connect(got_password_reply);
    mount_op.ask_password("", id, "",
                          AskPasswordFlags.NEED_PASSWORD |
                          AskPasswordFlags.NEED_USERNAME |
                          AskPasswordFlags.SAVING_SUPPORTED);
  }

  void got_secret_key() {
    var settings = get_settings(RACKSPACE_ROOT);
    if (id != settings_id)
      settings.set_string(RACKSPACE_USERNAME_KEY, id);

    List<string> envp = new List<string>();
    envp.append("CLOUDFILES_USERNAME=%s".printf(id));
    envp.append("CLOUDFILES_APIKEY=%s".printf(secret_key));
    envp_ready(true, envp);
  }
}

} // end namespace

