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

public class RecursiveDelete : RecursiveOp
{
  public RecursiveDelete(File source)
  {
    Object(src: source);
  }
  
  protected override void handle_file()
  {
    try {
      src.@delete(null);
    }
    catch (Error e) {
      raise_error(src, dst, e.message);
    }
  }
   
  protected override void finish_dir()
  {
    try {
      src.@delete(null); // will only be deleted if empty, so we won't
                         // accidentally toss files left over from a failed
                         // restore
    }
    catch (Error e) {
      // Ignore.  It's in /tmp, so it'll disappear, and most likely is just
      // a non-empty directory.
    }
  }
  
  protected override RecursiveOp clone_for_info(FileInfo info)
  {
    var child_name = info.get_name();
    var src_child = src.get_child(child_name);
    return new RecursiveDelete(src_child);
  }
}

} // namespace
