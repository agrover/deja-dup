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

public const string GOA_ROOT = "GOA";
public const string GOA_ID_KEY = "id";
public const string GOA_FOLDER_KEY = "folder";
public const string GOA_TYPE_KEY = "type";

public class BackendGOA : BackendRemote
{
  static Goa.Client _client;

  public BackendGOA(Settings? settings) {
    Object(settings: (settings != null ? settings : get_settings(GOA_ROOT)));
  }

  public override Backend clone() {
    return new BackendGOA(settings);
  }

  public static async Goa.Client get_client()
  {
    if (_client == null) {
      try {
        _client = yield new Goa.Client(null);
      } catch (Error e) {
        warning("Couldn't get GOA client: %s", e.message);
      }
    }
    return _client;
  }

  public static Goa.Client get_client_sync()
  {
    if (_client == null) {
      try {
        _client = new Goa.Client.sync(null);
      } catch (Error e) {
        warning("Couldn't get GOA client: %s", e.message);
      }
    }
    return _client;
  }

  protected override string get_folder()
  {
    return get_folder_key(settings, GOA_FOLDER_KEY, true);
  }

  public Goa.Object? get_object_from_settings()
  {
    var id = settings.get_string(GOA_ID_KEY);
    return get_client_sync().lookup_by_id(id);
  }

  protected override File? get_root_from_settings()
  {
    var obj = get_object_from_settings();
    if (obj == null)
      return null;
    var files = obj.get_files();
    if (files == null)
      return null;

    return File.new_for_uri(files.uri);
  }

  public static string get_provider_name(Goa.Account account)
  {
    // Use this until GNOME bug 787413 is fixed, which asks for service-
    // specific branding to be exposed.
    switch (account.provider_type) {
      case "google":
        return _("Google Drive");
      default:
        return account.provider_name;
    }
  }

  public override string get_location_pretty()
  {
    var obj = get_object_from_settings();
    if (obj == null)
      return "";
    var account = obj.get_account();
    return "%s (%s)".printf(get_provider_name(account), account.presentation_identity);
  }

  public override async bool is_ready(out string when)
  {
    var obj = get_object_from_settings();
    if (obj == null) {
      when = _("Backup will begin when a storage location is configured");
      return false;
    }

    var account = obj.get_account();
    // TODO: actually watch for files support turning on or off
    if (obj.get_files() == null || account.files_disabled) {
      // Translators: "Files" here is the string used in GNOME Online Account
      // settings checkbox for a given account to enable/disable an account's
      // Files feature.
      when = _("Backup will begin when ‘%s’ has Files support enabled").printf(get_location_pretty());
      return false;
    }

    return yield base.is_ready(out when);
  }

  public override Icon? get_icon()
  {
    var obj = get_object_from_settings();
    if (obj == null)
      return null;
    var account = obj.get_account();

    try {
      return Icon.new_for_string(account.provider_icon);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return null;
    }
  }

  protected override async void mount() throws Error
  {
    if (get_root_from_settings() == null) {
      var type = settings.get_string(GOA_TYPE_KEY);
      var provider = Goa.Provider.get_for_provider_type(type);

      var msg = _("Waiting for Online Accounts to be configured in your backup settings…");
      if (provider != null) {
        // Translators: %s is the name of the provider inside of GNOME Online Accounts
        msg = _("Waiting for %s to be configured in your backup settings…").printf(provider.get_provider_name(null));
      }

      pause_op(_("Storage location not available"), msg);
      var loop = new MainLoop(null, false);
      settings.changed[GOA_ID_KEY].connect(() => {
        if (get_root_from_settings() != null)
          loop.quit();
      });
      loop.run();
      pause_op(null, null);
    }

    yield base.mount();
  }
}
} // end namespace

