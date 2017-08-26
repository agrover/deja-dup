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

public const string LOCAL_ROOT = "Local";
public const string LOCAL_FOLDER_KEY = "folder";

public class BackendLocal : BackendFile
{
  public BackendLocal(Settings? settings) {
    Object(settings: (settings != null ? settings : get_settings(LOCAL_ROOT)));
  }

  public override Backend clone() {
    return new BackendLocal(settings);
  }

  // Get mountable root
  protected override File? get_root_from_settings()
  {
    return File.new_for_path(Environment.get_home_dir());
  }

  // Get full URI to backup folder
  protected override File? get_file_from_settings()
  {
    var root = get_root_from_settings();
    var folder = get_folder_key(settings, LOCAL_FOLDER_KEY, true);

    try {
      return root.get_child_for_display_name(folder);
    } catch (Error e) {
      warning("%s", e.message);
      return null;
    }
  }

  public override Icon? get_icon()
  {
    try {
      return Icon.new_for_string("folder");
    }
    catch (Error e) {}

    return null;
  }
}

} // end namespace
