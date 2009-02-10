/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008—2009 Michael Terry <mike@mterry.name>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using GLib;

namespace DejaDup {

public const string S3_ID_KEY = "/apps/deja-dup/s3/id";
public const string S3_BUCKET_KEY = "/apps/deja-dup/s3/bucket";
public const string S3_FOLDER_KEY = "/apps/deja-dup/s3/folder";

const string S3_SERVER = "s3.amazonaws.com";

public class BackendS3 : Backend
{
  public BackendS3(Gtk.Window? win) {
    toplevel = win;
  }
  
  public override Backend clone() {
    return new BackendS3(toplevel);
  }
  
  public override void add_argv(ref List<string> argv) {
    argv.append("--s3-use-new-style");
  }
  
  public override string? get_location() throws Error
  {
    var client = GConf.Client.get_default();
    
    var bucket = client.get_string(S3_BUCKET_KEY);
    var default_bucket = "deja-dup-auto-%s".printf(id.down());
    if (bucket == null || bucket == "" ||
        (bucket.has_prefix("deja-dup-auto-") &&
         !bucket.has_prefix(default_bucket))) {
      bucket = default_bucket;
      client.set_string(S3_BUCKET_KEY, bucket);
    }
    
    var folder = client.get_string(S3_FOLDER_KEY);
    if (folder != null && folder != "") {
      if (folder[0] != '/')
        bucket = "%s/%s".printf(bucket, folder);
      else
        bucket = "%s%s".printf(bucket, folder);
    }
    
    return "s3+http://%s".printf(bucket);
  }
  
  public bool bump_bucket() {
    // OK, the bucket we tried must already exist, so let's use a different
    // one.  We'll take previous bucket name and increment it.
    try {
      var client = GConf.Client.get_default();
      
      var bucket = client.get_string(S3_BUCKET_KEY);
      if (!bucket.has_prefix("deja-dup-auto-"))
        return false;
      
      var bits = bucket.split("-");
      if (bits == null || bits[0] == null || bits[1] == null ||
          bits[2] == null || bits[3] == null)
        return false;
      
      if (bits[4] == null)
        bucket += "-2";
      else {
        var num = bits[4].to_long();
        bits[4] = (num + 1).to_string();
        bucket = string.joinv("-", bits);
      }
      
      client.set_string(S3_BUCKET_KEY, bucket);
      return true;
    }
    catch (Error e) {
      return false;
    }
  }
  
  public override string? get_location_pretty() throws Error
  {
    var client = GConf.Client.get_default();
    var folder = client.get_string(S3_FOLDER_KEY);
    if (folder == null || folder == "")
      folder = "/";
    
    return _("Folder %s on Amazon S3").printf(folder);
  }
  
  string gconf_id;
  string id;
  string secret_key;
  public override void get_envp() throws Error
  {
    var client = GConf.Client.get_default();
    gconf_id = client.get_string(S3_ID_KEY);
    id = gconf_id == null ? "" : gconf_id;
    
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
      need_password();
  }
  
  void found_password(GnomeKeyring.Result result, GLib.List? list)
  {
    if (result == GnomeKeyring.Result.OK && list != null) {
      secret_key = ((GnomeKeyring.NetworkPasswordData)list.data).password;
      got_secret_key();
    }
    else {
      need_password();
    }
  }
  
  void save_password_callback(GnomeKeyring.Result result, uint32 val)
  {
  }
  
  public override void ask_password() {
    // Ask user
    var dlg = new Gnome.PasswordDialog(_("Amazon S3 Password"),
                                       _("Enter your Amazon Web Services user ID and secret key.  This is not the same as your amazon.com username and password."),
                                       id, "", false);
    dlg.transient_parent = toplevel;
    dlg.show_remember = true;
    if (!dlg.run_and_block()) {
      envp_ready(false, new List<string>());
      return;
    }
    
    id = dlg.get_username();
    secret_key = dlg.get_password();
    
    // Save it
    var remember = dlg.get_remember();
    if (remember != Gnome.PasswordDialogRemember.NOTHING) {
      string where = remember == Gnome.PasswordDialogRemember.SESSION ?
                                 "session" : GnomeKeyring.DEFAULT;
      GnomeKeyring.set_network_password(where, id, null, S3_SERVER, null,
                                        "https", null, 0, secret_key,
                                        save_password_callback);
    }
    
    got_secret_key();
  }
  
  void got_secret_key() {
    var client = GConf.Client.get_default();
    if (id != gconf_id) {
      try {
        client.set_string(S3_ID_KEY, id);
      }
      catch (Error e) {warning("%s\n", e.message);}
    }
    
    List<string> envp = new List<string>();
    envp.append("AWS_ACCESS_KEY_ID=%s".printf(id));
    envp.append("AWS_SECRET_ACCESS_KEY=%s".printf(secret_key));
    envp_ready(true, envp);
  }
}

} // end namespace

