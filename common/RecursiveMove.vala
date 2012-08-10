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

/**
 * Recursively moves one directory into another, merging files.  And by merge,
 * I mean it overwrites.  It skips any files it can't move and reports an
 * error, but keeps going.
 *
 * This is not optimized for remote files.  It's mostly async, but it does the
 * occasional sync operation.
 */
public class RecursiveMove : RecursiveOp
{
  public RecursiveMove(File source, File dest)
  {
    Object(src: source, dst: dest);
  }
  
  void progress_callback(int64 current_num_bytes, int64 total_num_bytes)
  {
    // Do nothing right now
  }
  
  protected override void handle_file()
  {
    if (dst_type == FileType.DIRECTORY) {
      // GIO will throw a fit if we try to overwrite a directory with a file.
      // So cleanly delete directory first.
      
      // We don't care about doing this 100% atomically, since user is
      // intending to restore files to a previous state and implicitly doesn't
      // worry about current state as long as we restore.  It kinda sucks that
      // we'd just delete a bunch of files and possibly not restore the original
      // file, but chances are low that the following move will fail...  But
      // not guaranteed.  It'd be nice to make this more perfect.
      try {
        dst.@delete(null);
      }
      catch (Error e) {
        raise_error(src, dst, e.message);
        return;
      }
    }
    
    try {
      src.move(dst,
               FileCopyFlags.ALL_METADATA |
               FileCopyFlags.NOFOLLOW_SYMLINKS |
               FileCopyFlags.OVERWRITE,
               null,
               progress_callback);
    }
    catch (IOError.PERMISSION_DENIED e) {
      // Try just copying it (in case we didn't have write access to src's
      // parent directory).
      try {
        src.copy(dst,
                 FileCopyFlags.ALL_METADATA |
                 FileCopyFlags.NOFOLLOW_SYMLINKS |
                 FileCopyFlags.OVERWRITE,
                 null,
                 progress_callback);
      }
      catch (Error e) {
        raise_error(src, dst, e.message);
      }
    }
    catch (Error e) {
      raise_error(src, dst, e.message);
    }
  }
  
  protected override void handle_dir()
  {
    if (dst_type != FileType.UNKNOWN && dst_type != FileType.DIRECTORY) {
      // Hmmm...  Something that's not a directory is in our way.
      // Move dst file out of the way before we continue, else GIO will
      // complain.
      
      // We don't care about doing this 100% atomically, since user is
      // intending to restore files to a previous state and implicitly doesn't
      // worry about current state as long as we restore.  If we can delete
      // it, we can create a directory in its place (i.e. restore of this
      // directory is not likely to fail in a few seconds), so let's just blow
      // it away.
      try {
        dst.@delete(null);
      }
      catch (Error e) {
        raise_error(src, dst, e.message);
        return;
      }
      
      dst_type = FileType.UNKNOWN; // now the file's gone
    }
    
    if (dst_type == FileType.UNKNOWN) {
      // Create it.  The GIO move function does not guarantee that we can move
      // whole folders across filesystems.  So we'll just create it and
      // descend.  Easy enough.
      try {
        dst.make_directory(null);
      }
      catch (Error e) {
        raise_error(src, dst, e.message);
        return;
      }
    }
  }
  
  protected override void finish_dir()
  {
    // Now, we'll try to change it's settings to match our restore copy.
    // If we tried to do this first, we may remove write access before trying
    // to copy subfiles.
    try {
      src.copy_attributes(dst,
                          FileCopyFlags.NOFOLLOW_SYMLINKS |
                          FileCopyFlags.ALL_METADATA,
                          null);
    }
    catch (Error e) {
      // If we fail, no big deal.  There'll often be stuff like /home that we
      // can't change and don't care about changing.
    }

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
    var dst_child = dst.get_child(child_name);
    return new RecursiveMove(src_child, dst_child);
  }
}

} // namespace
