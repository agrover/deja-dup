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

public const string S3_ROOT = "S3";
public const string S3_ID_KEY = "id";
public const string S3_BUCKET_KEY = "bucket";
public const string S3_FOLDER_KEY = "folder";

const string S3_SERVER = "s3.amazonaws.com";

public class BackendS3 : Backend
{
  public static Checker get_checker() {
    return PythonChecker.get_checker("boto");
  }

  public override Backend clone() {
    return new BackendS3();
  }
  
  public override void add_argv(ToolJob.Mode mode, ref List<string> argv) {
    if (mode == ToolJob.Mode.INVALID)
      argv.append("--s3-use-new-style");
  }
  
  string get_default_bucket() {
    return "deja-dup-auto-%s".printf(id.down());
  }

  public override bool is_native() {
    return false;
  }
  
  public override Icon? get_icon() {
    return new ThemedIcon("deja-dup-cloud");
  }

  public override async bool is_ready(out string when) {
    when = _("Backup will begin when a network connection becomes available.");
    return yield Network.get().can_reach ("http://%s/".printf(S3_SERVER));
  }

  public override string get_location(ref bool as_root)
  {
    var settings = get_settings(S3_ROOT);
    
    var bucket = settings.get_string(S3_BUCKET_KEY);
    var default_bucket = get_default_bucket();
    if (bucket == null || bucket == "" ||
        (bucket.has_prefix("deja-dup-auto-") &&
         !bucket.has_prefix(default_bucket))) {
      bucket = default_bucket;
      settings.set_string(S3_BUCKET_KEY, bucket);
    }
    
    var folder = get_folder_key(settings, S3_FOLDER_KEY);
    return "s3+http://%s/%s".printf(bucket, folder);
  }
  
  public bool bump_bucket() {
    // OK, the bucket we tried must already exist, so let's use a different
    // one.  We'll take previous bucket name and increment it.
    var settings = get_settings(S3_ROOT);
    
    var bucket = settings.get_string(S3_BUCKET_KEY);
    if (bucket == "deja-dup") {
      // Until 7.4, we exposed the bucket name and defaulted to deja-dup.
      // Since buckets are S3-global, everyone was unable to use that bucket,
      // since I (Mike Terry) owned that bucket.  If we see this setting,
      // we should default to the generic bucket name rather than assume the
      // user chose this bucket and error out.
      bucket = get_default_bucket();
      settings.set_string(S3_BUCKET_KEY, bucket);
      return true;
    }
    
    if (!bucket.has_prefix("deja-dup-auto-"))
      return false;
    
    var bits = bucket.split("-");
    if (bits == null || bits[0] == null || bits[1] == null ||
        bits[2] == null || bits[3] == null)
      return false;
    
    if (bits[4] == null)
      bucket += "-2";
    else {
      var num = long.parse(bits[4]);
      bits[4] = (num + 1).to_string();
      bucket = string.joinv("-", bits);
    }
    
    settings.set_string(S3_BUCKET_KEY, bucket);
    return true;
  }
  
  public override string get_location_pretty()
  {
    var settings = get_settings(S3_ROOT);
    var folder = get_folder_key(settings, S3_FOLDER_KEY);
    if (folder == "")
      return _("Amazon S3");
    else
      // Translators: %s is a folder.
      return _("%s on Amazon S3").printf(folder);
  }
  
  string settings_id;
  string id;
  string secret_key;
  public override async void get_envp() throws Error
  {
    var settings = get_settings(S3_ROOT);
    settings_id = settings.get_string(S3_ID_KEY);
    id = settings_id == null ? "" : settings_id;
    
    if (id != "" && secret_key != null) {
      // We've already been run before and got the key
      got_secret_key();
      return;
    }
    
    if (id != "") {
      // First, try user's keyring
      secret_key = null;
      GnomeKeyring.find_network_password(id, null, S3_SERVER, null, "https",
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
      GnomeKeyring.set_network_password(where, id, null, S3_SERVER, null,
                                        "https", null, 0, secret_key,
                                        save_password_callback);
    }
    
    got_secret_key();
  }

  void ask_password() {
    mount_op.set("label_help", _("You can sign up for an Amazon S3 account <a href=\"%s\">online</a>.").printf("http://aws.amazon.com/s3/"));
    mount_op.set("label_title", _("Connect to Amazon S3"));
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
    var settings = get_settings(S3_ROOT);
    if (id != settings_id)
      settings.set_string(S3_ID_KEY, id);
    
    List<string> envp = new List<string>();
    envp.append("AWS_ACCESS_KEY_ID=%s".printf(id));
    envp.append("AWS_SECRET_ACCESS_KEY=%s".printf(secret_key));
    envp_ready(true, envp);
  }
}

} // end namespace

