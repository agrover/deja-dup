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

  // If vala supported a direct map syntax, I'd use that.  But instead, let's
  // use two arrays.
  string[] dirs = { "$DESKTOP", "$DOCUMENTS", "$DOWNLOAD", "$MUSIC",
                    "$PICTURES", "$PUBLIC_SHARE", "$TEMPLATES", "$VIDEOS" };
  UserDirectory[] enums = { UserDirectory.DESKTOP, UserDirectory.DOCUMENTS,
                            UserDirectory.DOWNLOAD, UserDirectory.MUSIC,
                            UserDirectory.PICTURES, UserDirectory.PUBLIC_SHARE,
                            UserDirectory.TEMPLATES, UserDirectory.VIDEOS };
  assert(dirs.length == enums.length);

  // Replace special variables when they are at the start of a larger path
  // The resulting string is an absolute path
  if (result.has_prefix("$HOME"))
    result = result.replace("$HOME", Environment.get_home_dir());
  else if (result.has_prefix("$TRASH"))
    result = result.replace("$TRASH", get_trash_path());
  else {
    for (int i = 0; i < dirs.length; i++) {
      if (result.has_prefix(dirs[i])) {
        var replacement = Environment.get_user_special_dir(enums[i]);
        if (replacement != null)
          result = result.replace(dirs[i], replacement);
        break;
      }
    }
  }

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

