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

public const string GDRIVE_ROOT = "GDrive";
public const string GDRIVE_EMAIL = "email";
public const string GDRIVE_FOLDER = "folder";

const string GDRIVE_HOST = "drive.google.com";

public class BackendGDrive : Backend

{
  public static Checker get_checker() {
    return PythonChecker.get_checker("gdata");
  }

  public override Backend clone() {
    return new BackendGDrive();
  }

  public override bool is_native() {
    return false;
  }

  public override Icon? get_icon() {
    return new ThemedIcon("deja-dup-cloud");
  }

  public override async bool is_ready(out string when) {
    when = _("Backup will begin when a network connection becomes available.");
    return yield Network.get().can_reach ("https://%s/".printf(GDRIVE_HOST));
  }

  /**
   * duplicity syntax:
   * gdocs://user[:password]@host/folder
   */
  public override string get_location(ref bool as_root)
  {
    var settings = get_settings(GDRIVE_ROOT);
    string folder = settings.get_string(GDRIVE_FOLDER);
    // TODO duplicity: gdocsbackend does not handle folder nice
    folder = folder.strip();
    folder = folder.replace("//", "/");
    while (folder.has_prefix ("/")) {
      folder = folder.substring(1, folder.length-1);
    }
    while (folder.has_suffix ("/")) {
      folder = folder.substring(0, folder.length-1);
    }
    string email = settings.get_string(GDRIVE_EMAIL);
    if (!email.contains("@"))
      email += "@gmail.com";
    string location = "gdocs://%s/%s".printf(email, folder);
    return location;
  }

  public override string get_location_pretty()
  {
    var settings = get_settings(GDRIVE_ROOT);
    // Translators: %s is a folder.
    return _("%s at Google Drive").printf(settings.get_string(GDRIVE_FOLDER));
  }

  string settings_id;
  string id;
  string secret_key;
  public override async void get_envp() throws Error
  {
    var settings = get_settings(GDRIVE_ROOT);
    settings_id = settings.get_string(GDRIVE_EMAIL);
    id = settings_id == null ? "" : settings_id;

    if (id != "" && secret_key != null) {
      // We've already been run before and got the key
      got_secret_key();
      return;
    }

    if (id != "") {
      // First, try user's keyring
      try {
        secret_key = yield Secret.password_lookup(Secret.SCHEMA_COMPAT_NETWORK,
                                                  null, 
                                                  "user", id,
                                                  "server", GDRIVE_HOST,
                                                  "protocol", "https");
        if (secret_key != null) {
          got_secret_key();
          return;
        }
      }
      catch (Error e) {
        // fall through to ask_password below
      }
    }

    // Didn't find it, so ask user
    ask_password();
  }

  async void got_password_reply(MountOperation mount_op, MountOperationResult result)
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
                     Secret.COLLECTION_SESSION : Secret.COLLECTION_DEFAULT;
      try {
        yield Secret.password_store(Secret.SCHEMA_COMPAT_NETWORK,
                                    where,
                                    "%s@%s".printf(id, GDRIVE_HOST),
                                    secret_key,
                                    null,
                                    "user", id,
                                    "server", GDRIVE_HOST,
                                    "protocol", "https");
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    }
    
    got_secret_key();
  }

  void ask_password() {
    mount_op.set("label_help", _("You can sign up for a Google account <a href=\"%s\">online</a>.").printf("https://accounts.google.com/SignUp"));
    mount_op.set("label_title", _("Connect to Google Drive"));
    mount_op.set("label_username", _("_Email"));
    mount_op.set("label_password", _("_Password"));
    mount_op.reply.connect(got_password_reply);
    mount_op.ask_password("", id, "",
                          AskPasswordFlags.NEED_PASSWORD |
                          AskPasswordFlags.NEED_USERNAME |
                          AskPasswordFlags.SAVING_SUPPORTED);
  }

  void got_secret_key() {
    var settings = get_settings(GDRIVE_ROOT);
    if (id != settings_id)
      settings.set_string(GDRIVE_EMAIL, id);

    List<string> envp = new List<string>();
    envp.append("FTP_PASSWORD=%s".printf(secret_key));
    envp_ready(true, envp);
  }
}

} // end namespace
