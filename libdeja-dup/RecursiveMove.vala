/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008 Michael Terry <mike@mterry.name>

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

/**
 * Recursively moves one directory into another, merging files.  And by merge,
 * I mean it overwrites.  It skips any files it can't move and reports an
 * error, but keeps going.
 *
 * This is not optimized for remote files.  It's mostly async, but it does the
 * occasional sync operation.
 */
public class RecursiveMove : Object
{
  public signal void done();
  public signal void raise_error(File src, File dst, string errstr);
  
  public File src {get; construct;}
  public File dst {get; construct;}
  
  int ref_count;
  FileType src_type;
  FileType dst_type;
  public RecursiveMove(File source, File dest)
  {
    this.src = source;
    this.dst = dest;
  }
  
  public bool start()
  {
    src_type = src.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
    dst_type = dst.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
    
    switch (src_type) {
    case FileType.DIRECTORY:
      move_dir();
      break;
    default:
      move_file();
      break;
    }
    
    check_ref();
    
    return true;
  }
  
  void progress_callback(int64 current_num_bytes, int64 total_num_bytes)
  {
    // Do nothing right now
  }
  
  void move_file()
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
    catch (Error e) {
      raise_error(src, dst, e.message);
    }
  }
  
  void move_dir()
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
    
    // Now, we'll try to change it's settings to match our restore copy
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
    
    // Now descend
    add_ref();
    move_children();
  }
  
  void move_children()
  {
    src.enumerate_children_async(FILE_ATTRIBUTE_STANDARD_NAME,
                                 FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                 Priority.DEFAULT, null,
                                 move_children_ready1);
  }
  
  static const int NUM_ENUMERATED = 16;
  void move_children_ready1(Object obj, AsyncResult res)
  {
    FileEnumerator enumerator;
    try {
      enumerator = src.enumerate_children_finish(res);
    }
    catch (Error e) {
      raise_error(src, dst, e.message);
      remove_ref(); // parent dir itself
      return;
    }
    
    enumerator.next_files_async(NUM_ENUMERATED, Priority.DEFAULT, null,
                                move_children_ready2);
  }
  
  void move_children_ready2(Object obj, AsyncResult res)
  {
    var enumerator = (FileEnumerator)obj;
    
    List<FileInfo> infos;
    try {
      infos = enumerator.next_files_finish(res);
    }
    catch (Error e) {
      raise_error(src, dst, e.message);
      remove_ref(); // parent dir itself
      return;
    }
    
    foreach (FileInfo info in infos) {
      var child_name = info.get_name();
      File src_child = src.get_child(child_name);
      File dst_child = dst.get_child(child_name);
      add_ref();
      var moveobj = new RecursiveMove(src_child, dst_child);
      moveobj.@ref();
      moveobj.done += (m) => {remove_ref(); m.unref();};
      moveobj.raise_error += (m, s, d, e) => {raise_error(s, d, e);}; // percolate up
      moveobj.start();
    }
    
    if (infos.length() == NUM_ENUMERATED)
      enumerator.next_files_async(NUM_ENUMERATED, Priority.DEFAULT, null,
                                  move_children_ready2);
    else
      remove_ref(); // parent dir itself
  }
  
  void finish_dir()
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
  
  void add_ref() {
    ++ref_count;
  }
  
  void remove_ref() {
    --ref_count;
    check_ref();
  }
  
  void check_ref() {
    if (ref_count == 0) {
      if (src_type == FileType.DIRECTORY)
        finish_dir();
      done();
    }
  }
}

} // end namespace

