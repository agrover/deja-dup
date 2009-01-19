/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*- */
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

public class Duplicity : Object
{
  public signal void done(bool success, bool cancelled);
  public signal void raise_error(string errstr, string? detail);
  public signal void action_desc_changed(string action);
  public signal void action_file_changed(File file);
  public signal void progress(double percent);
  public signal void collection_dates(List<string>? dates);
  
  public Gtk.Window toplevel {get; construct;}
  public Operation.Mode mode {get; private set;}
  public bool error_issued {get; private set; default = false;}
  
  protected enum State {
    NORMAL,
    DRY_RUN,
    CLEANUP
  }
  protected State state {get; set;}
  
  DuplicityInstance inst;
  
  string target;
  List<string> saved_argv;
  List<string> saved_envp;
  
  uint progress_total; // zero, unless we already know limit
  uint progress_count; // count of how far we are along in the current instance
  
  public Duplicity(Operation.Mode mode, Gtk.Window? win) {
    this.mode = mode;
    toplevel = win;
  }
  
  public virtual void start(string target, List<string> argv, List<string>? envp)
  {
    // save arguments for calling duplicity again later
    this.target = target;
    saved_argv = new List<string>();
    saved_envp = new List<string>();
    foreach (string s in argv) saved_argv.append(s);
    foreach (string s in envp) saved_envp.append(s);
    
    restart();
  }
  
  public void cancel() {
    var old_mode = mode;
    mode = Operation.Mode.INVALID;
    
    if (old_mode == Operation.Mode.BACKUP) {
      if (cleanup())
        return;
    }
    
    inst.cancel();
  }
  
  bool restart()
  {
    state = State.NORMAL;
    
    if (mode == Operation.Mode.INVALID)
      return false;
    
    // If we're backing up, and the version of duplicity supports it, we should
    // first run using --dry-run to get the total size of the backup, to make
    // accurate progress bars.
    if (mode == Operation.Mode.BACKUP &&
        DuplicityInfo.get_default().has_backup_progress &&
        progress_total == 0) {
      action_desc_changed(_("Preparing..."));
      state = State.DRY_RUN;
      
      var extra_argv = new List<string>();
      extra_argv.append("--dry-run");
      connect_and_start(extra_argv);
      
      return true;
    }
    
    // Send appropriate description for what we're about to do.  Is often
    // very quickly overridden by a message like "Backing up file X"
    action_desc_changed(Operation.mode_to_string(mode));
    
    connect_and_start();
    return true;
  }
  
  bool cleanup() {
    if (DuplicityInfo.get_default().has_broken_cleanup ||
        state == State.CLEANUP)
      return false;
    
    state = State.CLEANUP;
    var cleanup_argv = new List<string>();
    cleanup_argv.append("cleanup");
    cleanup_argv.append("--force");
    cleanup_argv.append(this.target);
    
    action_desc_changed(_("Cleaning up..."));
    connect_and_start(null, null, cleanup_argv);
    
    return true;
  }
  
  void handle_done(DuplicityInstance inst, bool success, bool cancelled)
  {
    if (!cancelled) {
      switch (state) {
      case State.DRY_RUN:
        if (success) {
          progress_total = progress_count; // save max progress for next run
          state = State.NORMAL;
          connect_and_start();
          return;
        }
        break;
      
      case State.CLEANUP:
        if (restart()) // restart in case cleanup was interrupting normal flow
          return;
        
        // Else, we probably started cleaning up after a cancel.  Just continue
        // that cancel
        success = false;
        cancelled = true;
        break;
      }
    }
    
    if (!success && !cancelled && !error_issued)
      show_error(_("Failed with an unknown error."));
    
    inst = null;
    done(success, cancelled);
  }
  
  protected static const int ERROR_EXCEPTION = 30;
  protected static const int INFO_PROGRESS = 2;
  protected static const int INFO_COLLECTION_STATUS = 3;
  protected static const int INFO_DIFF_FILE_NEW = 4;
  protected static const int INFO_DIFF_FILE_CHANGED = 5;
  protected static const int INFO_DIFF_FILE_DELETED = 6;
  protected static const int INFO_PATCH_FILE_WRITING = 7;
  protected static const int INFO_PATCH_FILE_PATCHING = 8;
  protected static const int WARNING_ORPHANED_SIG = 2;
  protected static const int WARNING_UNNECESSARY_SIG = 3;
  protected static const int WARNING_UNMATCHED_SIG = 4;
  protected static const int WARNING_INCOMPLETE_BACKUP = 5;
  protected static const int WARNING_ORPHANED_BACKUP = 6;
  
  void handle_message(DuplicityInstance inst, string[] control_line,
                      List<string>? data_lines, string user_text)
  {
    if (control_line.length == 0)
      return;
    
    var keyword = control_line[0];
    switch (keyword) {
    case "ERROR":
      process_error(control_line, data_lines, user_text);
      break;
    case "INFO":
      process_info(control_line, data_lines, user_text);
      break;
    case "WARNING":
      process_warning(control_line, data_lines, user_text);
      break;
    }
  }
  
  protected virtual void process_error(string[] firstline, List<string>? data,
                                       string text)
  {
    if (firstline.length > 1) {
      switch (firstline[1].to_int()) {
      case ERROR_EXCEPTION: // exception
        process_exception(firstline.length > 2 ? firstline[2] : "", text);
        return;
      }
    }
    
    show_error(text);
  }
  
  void process_exception(string exception, string text)
  {
    switch (exception) {
    case "S3ResponseError":
      if (text.str("<Code>InvalidAccessKeyId</Code>") != null)
        show_error(_("Invalid ID"));
      else if (text.str("<Code>SignatureDoesNotMatch</Code>") != null)
        show_error(_("Invalid secret key"));
      break;
    case "IOError":
      // Very possibly a FAT file system that can't handle the colons that 
      // duplicity likes to use.  Try again with --short-filenames
      // But first make sure we aren't already doing that.
      bool found = false;
      foreach (string s in saved_argv) {
        if (s == "--short-filenames") {
          found = true;
          break;
        }
      }
      if (!found) {
        saved_argv.append("--short-filenames");
        connect_and_start();
        return;
      }
      break;
    }
    
    // For most, don't do anything. Error string won't be useful to humans, and
    // by not raising it, we'll eventually hit the 'unknown error'
    // message which is slightly better than a giant exception string.
  }
  
  protected virtual void process_info(string[] firstline, List<string>? data,
                                      string text)
  {
    if (firstline.length > 1) {
      switch (firstline[1].to_int()) {
      case INFO_DIFF_FILE_NEW:
      case INFO_DIFF_FILE_CHANGED:
      case INFO_DIFF_FILE_DELETED:
        if (firstline.length > 2)
          process_diff_file(firstline[2]);
        break;
      case INFO_PATCH_FILE_WRITING:
      case INFO_PATCH_FILE_PATCHING:
        if (firstline.length > 2)
          process_patch_file(firstline[2]);
        break;
      case INFO_PROGRESS:
        process_progress(firstline);
        break;
      case INFO_COLLECTION_STATUS:
        process_collection_status(data);
        break;
      }
    }
  }
  
  void process_diff_file(string file) {
    action_file_changed(make_file_obj(file));
  }
  
  void process_patch_file(string file) {
    action_file_changed(make_file_obj(file));
  }
  
  void process_progress(string[] firstline)
  {
    if (!DuplicityInfo.get_default().has_restore_progress &&
        mode == Operation.Mode.RESTORE)
      return;
    
    uint total;
    
    if (firstline.length > 2)
      this.progress_count = firstline[2].to_int();
    else
      return;
    
    if (firstline.length > 3)
      total = firstline[3].to_int();
    else if (this.progress_total > 0)
      total = this.progress_total;
    else
      return; // can't do progress without a total
    
    double percent = this.progress_count / (double)total;
    if (percent > 1)
      percent = 1;
    if (percent < 0) // ???
      percent = 0;
    progress(percent);
  }
  
  static File root;
  File make_file_obj(string file)
  {
    // All files are relative to root.
    if (root == null)
      root = File.new_for_path("/");
    
    return root.resolve_relative_path(file);
  }
  
  void process_collection_status(List<string>? lines)
  {
    // Collection status is a bunch of lines, some of which are indented,
    // which contain information about specific chains.  We gather this all up
    // and report back to caller via a signal.
    // We're really only interested in the list of entries in the complete chain,
    // though.
    
    var timeval = TimeVal();
    var dates = new List<string>();
    bool in_chain = false;
    foreach (string line in lines) {
      print("looking at line: %s\n", line);
      if (line == "chain-complete")
        in_chain = true;
      else if (in_chain && line.length > 0 && line[0] == ' ') {
        // OK, appears to be a date line.  Try to parse.  Should look like:
        // ' inc TIMESTR NUMVOLS'.  Since there's a space at the beginnning,
        // when we tokenize it, we should expect an extra token at the front.
        string[] tokens = line.split(" ");
        if (tokens.length > 2 && timeval.from_iso8601(tokens[2]))
          dates.append(tokens[2]);
      }
      else if (in_chain)
        in_chain = false;
    }
    
    collection_dates(dates);
  }
  
  protected virtual void process_warning(string[] firstline, List<string>? data,
                                         string text)
  {
    if (firstline.length > 1) {
      switch (firstline[1].to_int()) {
      case WARNING_ORPHANED_SIG:
      case WARNING_UNNECESSARY_SIG:
      case WARNING_UNMATCHED_SIG:
      case WARNING_INCOMPLETE_BACKUP:
      case WARNING_ORPHANED_BACKUP:
        // Random files left on backend from previous run.  Should clean them
        // up before we continue.  We don't want to wait until we finish to
        // clean them up, since we may want that space, and if there's a bug
        // in ourselves, we may never get to it.
        cleanup(); // stops current backup, cleans up, then resumes
      break;
      }
    }
  }
  
  void show_error(string errorstr)
  {
    error_issued = true;
    raise_error(errorstr, null);
  }
  
  void connect_and_start(List<string>? argv_extra = null,
                         List<string>? envp_extra = null,
                         List<string>? argv_entire = null)
  {
    if (inst != null) {
      inst.done -= handle_done;
      inst.message -= handle_message;
      inst.cancel();
    }
    
    inst = new DuplicityInstance();
    inst.done += handle_done;
    inst.message += handle_message;
    
    weak List<string> master_argv = argv_entire == null ? saved_argv : argv_entire;
    
    var argv = new List<string>();
    foreach (string s in master_argv) argv.append(s);
    foreach (string s in argv_extra) argv.append(s);
    
    var envp = new List<string>();
    foreach (string s in saved_envp) envp.append(s);
    foreach (string s in envp_extra) envp.append(s);
    
    try {
      inst.start(argv, envp);
    }
    catch (Error e) {
      show_error(e.message);
      done(false, false);
    }
  }
}

} // end namespace

