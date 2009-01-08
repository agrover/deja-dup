/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
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

public abstract class RecursiveOp : Object
{
  public signal void done();
  public signal void raise_error(File src, File dst, string errstr);
  
  public File src {get; construct;}
  public File dst {get; construct;}
  
  protected FileType src_type;
  protected FileType dst_type;
  protected virtual void handle_file() {} // src is file
  protected virtual void handle_dir() {} // src is dir
  protected virtual void finish_dir() {} // src is dir we are done with
  protected abstract RecursiveOp clone_for_info(FileInfo info);
  
  int ref_count;
  
  bool idle_action()
  {
    start_async();
    return false;
  }
  
  public void start()
  {
    Idle.add(idle_action);
    done += (m) => {Gtk.main_quit();};
    Gtk.main();
  }
  
  public void start_async()
  {
    if (src != null)
      src_type = src.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
    if (dst != null)
      dst_type = dst.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
    
    switch (src_type) {
    case FileType.DIRECTORY:
      do_dir();
      break;
    default:
      handle_file();
      break;
    }
    
    check_ref();
  }
  
  void do_dir()
  {
    handle_dir();
    
    // Now descend
    add_ref();
    do_children();
  }
  
  void do_children()
  {
    src.enumerate_children_async(FILE_ATTRIBUTE_STANDARD_NAME,
                                 FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                 Priority.DEFAULT, null,
                                 do_children_ready1);
  }
  
  static const int NUM_ENUMERATED = 16;
  void do_children_ready1(Object obj, AsyncResult res)
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
                                do_children_ready2);
  }
  
  void do_children_ready2(Object obj, AsyncResult res)
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
      add_ref();
      var op = clone_for_info(info);
      op.@ref();
      op.done += (m) => {remove_ref(); m.unref();};
      op.raise_error += (m, s, d, e) => {raise_error(s, d, e);}; // percolate up
      op.start_async();
    }
    
    if (infos.length() == NUM_ENUMERATED)
      enumerator.next_files_async(NUM_ENUMERATED, Priority.DEFAULT, null,
                                  do_children_ready2);
    else
      remove_ref(); // parent dir itself
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

