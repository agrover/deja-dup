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

public class ConfigURLPart : ConfigEntry
{
  public enum Part {
    SCHEME, SERVER, PORT, USER, FOLDER, DOMAIN
  }
  public Part part {get; construct;}

  public ConfigURLPart(Part part, string key, string ns="") {
    Object(key: key, ns: ns, part: part);
  }

  protected override async void set_from_config()
  {
    var userval = read_uri_part(settings, key, part);
    entry.set_text(userval);
  }

  public override void write_to_config()
  {
    var userval = entry.get_text();
    write_uri_part(settings, key, part, userval);
  }

  public static string read_uri_part(SimpleSettings settings, string key, Part part)
  {
    var uri = get_current_uri(settings, key);

    string text = null;

    switch (part) {
    case Part.SCHEME:
      text = uri.scheme;
      break;
    case Part.SERVER:
      text = uri.host;
      break;
    case Part.PORT:
      if (uri.port >= 0)
        text = uri.port.to_string();
      break;
    case Part.FOLDER:
      text = uri.path;
      break;
    case Part.USER:
      text = userinfo_get_user(uri.scheme, uri.userinfo);
      break;
    case Part.DOMAIN:
      text = userinfo_get_domain(uri.scheme, uri.userinfo);
      break;
    }

    if (text == null)
      text = "";

    return text;
  }

  public static void write_uri_part(SimpleSettings settings, string key, Part part, string userval)
  {
    var uri = get_current_uri(settings, key);

    switch (part) {
    case Part.SCHEME:
      uri.scheme = userval;
      break;
    case Part.SERVER:
      uri.host = userval;
      break;
    case Part.PORT:
      uri.port = int.parse(userval);
      if (uri.port == 0) // no one would really want 0, right?
        uri.port = -1;
      break;
    case Part.FOLDER:
      if (userval.has_prefix("/"))
        uri.path = userval;
      else
        uri.path = "/" + userval;
      break;
    case Part.USER:
      uri.userinfo = userinfo_set_user(uri.scheme, uri.userinfo, userval);
      break;
    case Part.DOMAIN:
      uri.userinfo = userinfo_set_domain(uri.scheme, uri.userinfo, userval);
      break;
    }

    scrub_uri(uri);

    var val = uri.encode_uri(true);
    settings.set_string(key, val);
  }

  static DejaDupDecodedUri get_current_uri(SimpleSettings settings, string key)
  {
    var val = settings.get_string(key);
    if (val == null)
      val = "";

    // First, try to parse as is.  What's stored in settings is actually a
    // GFile parse_name, but we'd like a first crack at it because passing
    // through GFile loses some info (like smb-domain-but-no-user becomes
    // no-domain-no-user).  So if it happens to be in URI form, let's parse it.
    var uri = DejaDupDecodedUri.decode_uri(val);
    if (uri == null) {
      var file = File.parse_name(val);
      uri = DejaDupDecodedUri.decode_uri(file.get_uri());
    }
    if (uri == null)
      uri = new DejaDupDecodedUri();
    return uri;
  }

  static string? userinfo_get_user(string? scheme, string? userinfo)
  {
    if (userinfo == null)
      return null;
    if (scheme == "smb" && userinfo.contains(";"))
      return userinfo.split(";", 2)[1];
    return userinfo;
  }

  static string? userinfo_get_domain(string? scheme, string? userinfo)
  {
    if (userinfo == null)
      return null;
    if (scheme == "smb" && userinfo.contains(";"))
      return userinfo.split(";", 2)[0];
    return null;
  }

  static string userinfo_set_user(string? scheme, string? userinfo, string user)
  {
    var domain = userinfo_get_domain(scheme, userinfo);
    if (domain != null)
      return "%s;%s".printf(domain, user);
    return user;
  }

  static string userinfo_set_domain(string? scheme, string? userinfo, string domain)
  {
    var user = userinfo_get_user(scheme, userinfo);
    if (user == null)
      user = "";
    if (domain == "")
      return user;
    return "%s;%s".printf(domain, user);
  }

  static void scrub_uri(DejaDupDecodedUri uri)
  {
    // Scrub local URIs of invalid information
    if (uri.scheme == null)
      uri.scheme = "file";
    if (uri.userinfo == "")
      uri.userinfo = null;
    if (uri.path == null)
      uri.path = "";

    switch (uri.scheme) {
    case "file":
      uri.port = -1;
      uri.host = null;
      uri.userinfo = null;
      break;
    case "smb":
      uri.port = -1;
      break;
    }
  }
}

}

