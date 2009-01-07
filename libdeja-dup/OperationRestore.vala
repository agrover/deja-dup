/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*- */
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

public class OperationRestore : Operation
{
  string dest; // Directory user wants to put files in
  string source; // Directory duplicity puts files in
  List<string> errors;
  
  public OperationRestore(Gtk.Window? win, string dest_in, uint xid = 0) {
    toplevel = win;
    uppermost_xid = xid;
    dest = dest_in;
    mode = Mode.RESTORE;
  }
  
  public override void start() throws Error
  {
    action_desc_changed(_("Restoring files..."));
    base.start();
  }
  
  protected override List<string>? make_argv() throws Error
  {
    var client = GConf.Client.get_default();
    
    var target = backend.get_location();    
    if (target == null)
      return null;
    
    source = Path.build_filename(Environment.get_tmp_dir(), "deja-dup-XXXXXX");
    source = DirUtils.mkdtemp(source);
    
    List<string> argv = new List<string>();
    argv.append("restore");
    if (!client.get_bool(ENCRYPT_KEY))
      argv.append("--no-encryption");
    argv.append(target);
    argv.append(source);
    return argv;
  }
  
  protected override void operation_finished(Duplicity dup, bool success, bool cancelled)
  {
    if (success) {
      fixup_home_dir();
      if (!mv_source_to_dest())
        success = false;
    }
    else if (!cancelled) {
      // Error case.  TODO: Should tell user about partial restore in /tmp
    }
    else
      cleanup_source();
    
    base.operation_finished(dup, success, cancelled);
  }
  
  /**
   * The idea here is to cover the following scenario:
   *   I backup my machine as user 'bob'
   *   I recover on another machine as user 'robert'
   * For the simple case (one home dir), we can note this and correct it.
   * We even cover the case of having backed up as root, and having a home dir
   * of /root.
   * 
   * This rejiggering is all done inside the source directory before we move it
   * to its destination.
   */
  void fixup_home_dir()
  {
    string ideal_home = Path.build_filename(source, Environment.get_home_dir());
    if (FileUtils.test(ideal_home, FileTest.EXISTS | FileTest.IS_DIR))
      return;
    
    // We check if there is only one /home/XXXXXX directory in restored files.
    // If so, we make sure it matches current user directory.
    string current_home = null;
    
    string strd = Path.build_filename(source, "home");
    Dir d;
    try                 { d = Dir.open(strd); }
    catch (FileError e) { d = null; }
    
    if (d != null) {
      string child = d.read_name();
      weak string end = d.read_name();
      if (end != null) {
        return; // more than one home dir, we don't know which they want
      }
      
      if (child != null) { // exactly one home dir, will rename
        current_home = Path.build_filename(strd, child);
        if (!FileUtils.test(current_home, FileTest.IS_DIR))
          current_home = null;
      }
    }
    
    if (current_home == null) { // hmm, no home dirs...  Check /root
      current_home = Path.build_filename(source, "root");
      if (!FileUtils.test(current_home, FileTest.EXISTS | FileTest.IS_DIR))
        current_home = null;
    }
    
    if (current_home != null) {
      // Ideal home may not have all parents ("/home" part) yet
      string dirname = Path.get_dirname(ideal_home);
      DirUtils.create_with_parents(dirname, 0755);
      
      FileUtils.rename(current_home, ideal_home);
    }
  }
  
  void show_errors()
  {
    // Various file errors piled up as we restored everything to its rightful
    // place.  Show them as a big ol' list, and let the user know that
    // they can still get the files in /tmp.
    var len = errors.length();
    string detail = null;
    
    if (len > 1) {
      string[] error_array = new string[len + 1];
      int i = 0;
      foreach (string err in errors)
        error_array[i++] = err;
      error_array[i] = null;
      detail = string.joinv("\n\n", error_array);
    }
    
    var error_text = _("Not all files could be restored. Any files that could not be restored may still be found in %s.").printf(source);
    if (detail == null)
      error_text += "\n\n" + errors.data;
    
    raise_error(error_text, detail);
  }
  
  void add_error(string relpath, string errstr)
  {
    errors.append(_("Could not restore %s: %s").printf(
                  relpath, errstr));
  }
  
  void mv_error(RecursiveMove move, File src, File dst, string errstr)
  {
    var dest_top = File.new_for_path(dest);
    var relative_dst = dest_top.get_relative_path(dst);
    if (relative_dst == null || relative_dst == "")
      relative_dst = dest;
    add_error(relative_dst, errstr);
  }
  
  bool mv_source_to_dest()
  {
    errors = new List<string>();
    
    File sourcef = File.new_for_path(source);
    File destf = File.new_for_path(dest);
    var move = new RecursiveMove(sourcef, destf);
    move.raise_error += mv_error;
    move.start();
    
    if (errors != null) {
      show_errors();
      return false;
    }
    else
      return true;
  }
  
  void cleanup_source()
  {
    File sourcef = File.new_for_path(source);
    var move = new RecursiveDelete(sourcef);
    move.start();
  }
}

} // end namespace

