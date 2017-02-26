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

public string get_trash_path()
{
  return Path.build_filename(Environment.get_user_data_dir(), "Trash");
}

public string? parse_keywords(string dir)
{
  string result = dir;

  // Replace special variables when they are at the start of a larger path
  // The resulting string is an absolute path
  if (result.has_prefix("$HOME"))
    result = result.replace("$HOME", Environment.get_home_dir());
  else if (result.has_prefix("$DESKTOP"))
    result = result.replace("$DESKTOP", Environment.get_user_special_dir(UserDirectory.DESKTOP));
  else if (result.has_prefix("$DOCUMENTS"))
    result = result.replace("$DOCUMENTS", Environment.get_user_special_dir(UserDirectory.DOCUMENTS));
  else if (result.has_prefix("$DOWNLOAD"))
    result = result.replace("$DOWNLOAD", Environment.get_user_special_dir(UserDirectory.DOWNLOAD));
  else if (result.has_prefix("$MUSIC"))
    result = result.replace("$MUSIC", Environment.get_user_special_dir(UserDirectory.MUSIC));
  else if (result.has_prefix("$PICTURES"))
    result = result.replace("$PICTURES", Environment.get_user_special_dir(UserDirectory.PICTURES));
  else if (result.has_prefix("$PUBLIC_SHARE"))
    result = result.replace("$PUBLIC_SHARE", Environment.get_user_special_dir(UserDirectory.PUBLIC_SHARE));
  else if (result.has_prefix("$TEMPLATES"))
    result = result.replace("$TEMPLATES", Environment.get_user_special_dir(UserDirectory.TEMPLATES));
  else if (result.has_prefix("$TRASH"))
    result = result.replace("$TRASH", get_trash_path());
  else if (result.has_prefix("$VIDEOS"))
    result = result.replace("$VIDEOS", Environment.get_user_special_dir(UserDirectory.VIDEOS));

  // Some variables can be placed anywhere in the path
  result = result.replace("$USER", Environment.get_user_name());

  // Relative paths are relative to the user's home directory
  if (Uri.parse_scheme(result) == null && !Path.is_absolute(result))
    result = Path.build_filename(Environment.get_home_dir(), result);

  return result;
}

public File? parse_dir(string dir)
{
  var result = parse_keywords(dir);
  if (result != null)
    return File.parse_name(result);
  else
    return null;
}

public File[] parse_dir_list(string*[] dirs)
{
  File[] rv = new File[0];
  
  foreach (string s in dirs) {
    var f = parse_dir(s);
    if (f != null)
      rv += f;
  }
  
  return rv;
}

} // end namespace

