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

public const string GCS_ROOT = "GCS";
public const string GCS_ID_KEY = "id";
public const string GCS_BUCKET_KEY = "bucket";
public const string GCS_FOLDER_KEY = "folder";

const string GCS_SERVER = "www.googleapis.com";

public class BackendGCS : Backend
{
  public BackendGCS(Settings? settings) {
    Object(settings: (settings != null ? settings : get_settings(GCS_ROOT)));
  }

  public override Backend clone() {
    return new BackendGCS(settings);
  }

  public override string[] get_dependencies()
  {
    return Config.BOTO_PACKAGES.split(",");
  }

  public override bool is_native() {
    return false;
  }
  
  public override Icon? get_icon() {
    return new ThemedIcon("deja-dup-cloud");
  }

  public override async bool is_ready(out string when) {
    when = _("Backup will begin when a network connection becomes available.");
    return yield Network.get().can_reach ("http://%s/".printf(GCS_SERVER));
  }

  public override string get_location(ref bool as_root)
  {
    var bucket = settings.get_string(GCS_BUCKET_KEY);
    var folder = get_folder_key(settings, GCS_FOLDER_KEY);

    return "gs://%s/%s".printf(bucket, folder);
  }
  
  public override string get_location_pretty()
  {
    var bucket = settings.get_string(GCS_BUCKET_KEY);
    var folder = get_folder_key(settings, GCS_FOLDER_KEY);
    if (folder == "")
      return _("Google Cloud Storage");
    else
      // Translators: %s/%s is a folder.
      return _("%s/%s on Google Cloud Storage").printf(bucket, folder);
  }
  
  string settings_id;
  string id;
  string secret_key;
  public override async void get_envp() throws Error
  {
    settings_id = settings.get_string(GCS_ID_KEY);
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
                                                  "server", GCS_SERVER,
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
                                    "%s@%s".printf(id, GCS_SERVER),
                                    secret_key,
                                    null,
                                    "user", id,
                                    "server", GCS_SERVER,
                                    "protocol", "https");
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    }

    got_secret_key();
  }

  void ask_password() {
    mount_op.set("label_help", _("You can sign up for a Google Cloud Storage account <a href=\"%s\">online</a>. Remember to enable Interoperability and create keys.").printf("http://cloud.google.com"));
    mount_op.set("label_title", _("Connect to Google Cloud Storage"));
    mount_op.set("label_username", _("_Access key ID"));
    mount_op.set("label_password", _("_Secret access key"));
    mount_op.set("label_show_password", _("S_how secret access key"));
    mount_op.set("label_remember_password", _("_Remember secret access key"));
    mount_op.reply.connect(got_password_reply);
    mount_op.ask_password("", id, "",
                          AskPasswordFlags.NEED_PASSWORD |
                          AskPasswordFlags.NEED_USERNAME |
                          AskPasswordFlags.SAVING_SUPPORTED);
  }
  
  void got_secret_key() {
    if (id != settings_id)
      settings.set_string(GCS_ID_KEY, id);
    
    List<string> envp = new List<string>();
    envp.append("GS_ACCESS_KEY_ID=%s".printf(id));
    envp.append("GS_SECRET_ACCESS_KEY=%s".printf(secret_key));
    envp_ready(true, envp);
  }
}

} // end namespace

