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
  string result = null;

  // Replace special variables when they are at the start of a larger path
  // The resulting string is an absolute path
  if (dir.has_prefix("$HOME"))
    result = dir.replace("$HOME", Environment.get_home_dir());
  else if (dir.has_prefix("$DESKTOP"))
    result = dir.replace("$DESKTOP", Environment.get_user_special_dir(UserDirectory.DESKTOP));
  else if (dir.has_prefix("$DOCUMENTS"))
    result = dir.replace("$DOCUMENTS", Environment.get_user_special_dir(UserDirectory.DOCUMENTS));
  else if (dir.has_prefix("$DOWNLOAD"))
    result = dir.replace("$DOWNLOAD", Environment.get_user_special_dir(UserDirectory.DOWNLOAD));
  else if (dir.has_prefix("$MUSIC"))
    result = dir.replace("$MUSIC", Environment.get_user_special_dir(UserDirectory.MUSIC));
  else if (dir.has_prefix("$PICTURES"))
    result = dir.replace("$PICTURES", Environment.get_user_special_dir(UserDirectory.PICTURES));
  else if (dir.has_prefix("$PUBLIC_SHARE"))
    result = dir.replace("$PUBLIC_SHARE", Environment.get_user_special_dir(UserDirectory.PUBLIC_SHARE));
  else if (dir.has_prefix("$TEMPLATES"))
    result = dir.replace("$TEMPLATES", Environment.get_user_special_dir(UserDirectory.TEMPLATES));
  else if (dir.has_prefix("$TRASH"))
    result = dir.replace("$TRASH", get_trash_path());
  else if (dir.has_prefix("$VIDEOS"))
    result = dir.replace("$VIDEOS", Environment.get_user_special_dir(UserDirectory.VIDEOS));
  else {
    // Some variables can be placed anywhere in the path
    result = dir.replace("$USER", Environment.get_user_name());

    // Relative paths are relative to the user's home directory
    if (Uri.parse_scheme(result) == null && !Path.is_absolute(result))
      result = Path.build_filename(Environment.get_home_dir(), result);
  }

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

