/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
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
  public Operation.Mode original_mode {get; private set;}
  public Operation.Mode mode {get; private set;}
  public bool error_issued {get; private set; default = false;}
  
  public string local {get; set;}
  public Backend backend {get; set;}
  
  private List<File> _restore_files;
  public List<File> restore_files {
    get {
      return this._restore_files;
    }
    set {
      foreach (File f in this._restore_files)
        f.unref();
      this._restore_files = value.copy();
      foreach (File f in this._restore_files)
        f.ref();
    }
  }
  
  protected enum State {
    NORMAL,
    DRY_RUN, // used when backing up, and we need to first get time estimate
    STATUS, // used when backing up, and we need to first get collection info
    CLEANUP
  }
  protected State state {get; set;}
  
  DuplicityInstance inst;
  
  string remote;
  List<string> backend_argv;
  List<string> saved_argv;
  List<string> saved_envp;
  
  bool has_progress_total = false;
  double progress_total; // zero, unless we already know limit
  double progress_count; // count of how far we are along in the current instance
  
  bool checked_collection_info = false;
  bool got_collection_info = false;
  List<string> collection_info = null;
  
  public Duplicity(Operation.Mode mode, Gtk.Window? win) {
    this.mode = mode;
    this.original_mode = mode;
    toplevel = win;
  }
  
  public virtual void start(Backend backend, string remote, bool encrypted,
                            List<string>? argv, List<string>? envp)
  {
    // save arguments for calling duplicity again later
    this.remote = remote;
    this.backend = backend;
    saved_argv = new List<string>();
    saved_envp = new List<string>();
    backend_argv = new List<string>();
    foreach (string s in argv) saved_argv.append(s);
    foreach (string s in envp) saved_envp.append(s);
    backend.add_argv(Operation.Mode.INVALID, ref backend_argv);
    if (!encrypted)
      backend_argv.append("--no-encryption");
    
    if (!restart())
      done(false, false);
  }
  
  public void cancel() {
    var prev_mode = mode;
    mode = Operation.Mode.INVALID;
    
    if (prev_mode == Operation.Mode.BACKUP) {
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
    
    var extra_argv = new List<string>();
    string action_desc = null;
    string custom_local = null;
    
    switch (original_mode) {
    case Operation.Mode.BACKUP:
      // If duplicity is using the new time format, we need to first check if
      // the user has files in the old 'short-filenames' format.  If so, we'll
      // add to that chain.
      if (!checked_collection_info &&
          DuplicityInfo.get_default().has_collection_status) {
        mode = Operation.Mode.STATUS;
        state = State.STATUS;
        action_desc = _("Preparing...");
      }
      // If we're backing up, and the version of duplicity supports it, we should
      // first run using --dry-run to get the total size of the backup, to make
      // accurate progress bars.
      else if (DuplicityInfo.get_default().has_backup_progress &&
          !has_progress_total) {
        state = State.DRY_RUN;
        action_desc = _("Preparing...");
        extra_argv.append("--dry-run");
      }
      break;
    case Operation.Mode.RESTORE:
      if (restore_files != null) {
        // Just do first one.  Others will come when we're done
        
        // make path to specific restore file, since duplicity will just 
        // drop the file exactly where you ask it
        File local_file = File.new_for_path(local);
        File root = File.new_for_path("/");
        string rel_file_path = root.get_relative_path(restore_files.data);
        local_file = local_file.resolve_relative_path(rel_file_path);
        
        try {
          // won't have correct permissions...
          hacks_file_make_directory_with_parents(local_file);
        }
        catch (Error e) {
          show_error(e.message);
          return false;
        }
        custom_local = local_file.get_path();
        extra_argv.append("--file-to-restore=%s".printf(rel_file_path));
      }
      break;
    }
    
    // Send appropriate description for what we're about to do.  Is often
    // very quickly overridden by a message like "Backing up file X"
    if (action_desc == null)
      action_desc = Operation.mode_to_string(mode);
    action_desc_changed(action_desc);
    
    connect_and_start(extra_argv, null, null, custom_local);
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
    cleanup_argv.append(this.remote);
    
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
          has_progress_total = true;
          progress_total = progress_count; // save max progress for next run
          if (restart())
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
      
      case State.STATUS:
        if (success) {
          checked_collection_info = true;
          mode = Operation.Mode.BACKUP;
          
          if (!got_collection_info || collection_info == null) {
            // Checking for backup files added the short-filename parameter.
            // If there were no files, we want to take it out again and
            // proceed with a normal filename backup.
            foreach (weak string s in backend_argv) {
              if (s == "--short-filenames")
                backend_argv.remove(s);
            }
          }
          
          if (restart())
            return;
          else
            success = false;
        }
        break;
      
      case State.NORMAL:
        if (success && mode == Operation.Mode.RESTORE && restore_files != null) {
          _restore_files.delete_link(_restore_files);
          if (restore_files != null) {
            if (restart())
              return;
          }
        }
        break;
      }
    }
    
    if (error_issued)
      success = false;
    
    if (!success && !cancelled && !error_issued)
      show_error(_("Failed with an unknown error."));
    
    inst = null;
    done(success, cancelled);
  }
  
  bool restart_with_short_filenames_if_needed()
  {
    if (DuplicityInfo.get_default().can_read_short_filenames)
      return false;
    
    foreach (string s in backend_argv) {
      if (s == "--short-filenames")
        return false;
    }
    
    backend_argv.append("--short-filenames");
    if (!restart()) {
      done(false, false);
      return false;
    }
    
    return true;
  }
  
  protected static const int ERROR_RESTORE_DIR_NOT_FOUND = 19;
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
                                       string text_in)
  {
    string text = text_in;
    
    if (firstline.length > 1) {
      switch (firstline[1].to_int()) {
      case ERROR_EXCEPTION: // exception
        process_exception(firstline.length > 2 ? firstline[2] : "", text);
        return;
      case ERROR_RESTORE_DIR_NOT_FOUND:
        // make text a little nicer than duplicity gives
        // duplicity gives something like "home/blah/blah not found in archive,
        // no files restored".
        if (restore_files != null)
          text = _("Could not restore '%s': File not found in backup").printf(
                   restore_files.data.get_parse_name());
        break;
      }
    }
    
    show_error(text);
  }
  
  void process_exception(string exception, string text)
  {
    switch (exception) {
    case "S3ResponseError":
      if (text.str("<Code>InvalidAccessKeyId</Code>") != null)
        show_error(_("Invalid ID."));
      else if (text.str("<Code>SignatureDoesNotMatch</Code>") != null)
        show_error(_("Invalid secret key."));
      else if (text.str("<Code>NotSignedUp</Code>") != null)
        show_error(_("Your Amazon Web Services account is not signed up for the S3 service."));
      break;
    case "S3CreateError":
      if (text.str("<Code>BucketAlreadyExists</Code>") != null) {
        if (((BackendS3)backend).bump_bucket()) {
          remote = backend.get_location();
          restart();
        }
        else
          show_error(_("S3 bucket name is not available."));
      }
      break;
    case "IOError":
      if (text.str("GnuPG") != null)
        show_error(_("Bad encryption password."));
      else if (text.str("[Errno 28]") != null) { // No space left on device
        string where;
        if (mode == Operation.Mode.BACKUP)
          where = backend.get_location_pretty();
        else
          where = local;
        show_error(_("No space left in %s".printf(where)));
      }
      else {
        // Very possibly a FAT file system that can't handle the colons that 
        // duplicity likes to use.  Try again with --short-filenames
        // But first make sure we aren't already doing that.
        // Happens on backup only.
        if (!DuplicityInfo.get_default().new_time_format)
          restart_with_short_filenames_if_needed();
      }
      break;
    case "CollectionsError":
      // Very possibly a FAT file system that we are trying to restore from.
      // Duplicity can't find the short filenames that duplicity uses and
      // throws an exception. We should try again with --short-filenames.
      // Note that this code path is unlikely to have been hit on recent
      // versions of duplicity (ones with parsable collection-status support)
      // because when we run collection-status and see no backups, we add
      // --short-filenames to argv then.
      if (restart_with_short_filenames_if_needed())
        show_error(_("No backup files found"));
      break;
    }
    
    // For most, don't do anything special.  Show generic 'unknown error'
    // message, but provide the exception text for better bug reports.
    // Plus, sometimes it may clue the user in to what's wrong.
    if (!error_issued)
      show_error(_("Failed with an unknown error."), text);
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
    if (state != State.DRY_RUN)
      action_file_changed(make_file_obj(file));
  }
  
  void process_patch_file(string file) {
    if (state != State.DRY_RUN)
      action_file_changed(make_file_obj(file));
  }
  
  void process_progress(string[] firstline)
  {
    if (!DuplicityInfo.get_default().has_restore_progress &&
        mode == Operation.Mode.RESTORE)
      return;
    
    double total;
    
    if (firstline.length > 2)
      this.progress_count = firstline[2].to_double();
    else
      return;
    
    if (firstline.length > 3)
      total = firstline[3].to_double();
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
      if (line == "chain-complete")
        in_chain = true;
      else if (in_chain && line.length > 0 && line[0] == ' ') {
        // OK, appears to be a date line.  Try to parse.  Should look like:
        // ' inc TIMESTR NUMVOLS'.  Since there's a space at the beginning,
        // when we tokenize it, we should expect an extra token at the front.
        string[] tokens = line.split(" ");
        if (tokens.length > 2 && timeval.from_iso8601(tokens[2]))
          dates.append(tokens[2]);
      }
      else if (in_chain)
        in_chain = false;
    }
    
    if (mode == Operation.Mode.STATUS &&
        dates.length() == 0) { // may not have found short-filenamed-backups
      if (restart_with_short_filenames_if_needed())
        return;
    }
    
    got_collection_info = true;
    collection_info = new List<string>();
    foreach (string s in dates)
      collection_info.append(s); // we want to keep our own copy too
    
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
  
  void show_error(string errorstr, string? detail = null)
  {
    if (error_issued == false) {
      error_issued = true;
      raise_error(errorstr, detail);
    }
  }
  
  void connect_and_start(List<string>? argv_extra = null,
                         List<string>? envp_extra = null,
                         List<string>? argv_entire = null,
                         string? custom_local = null)
  {
    if (inst != null) {
      inst.done.disconnect(handle_done);
      inst.message.disconnect(handle_message);
      inst.cancel();
    }
    
    inst = new DuplicityInstance();
    inst.done.connect(handle_done);
    inst.message.connect(handle_message);
    
    weak List<string> master_argv = argv_entire == null ? saved_argv : argv_entire;
    weak string local_arg = custom_local == null ? local : custom_local;
    
    var argv = new List<string>();
    foreach (string s in master_argv) argv.append(s);
    foreach (string s in argv_extra) argv.append(s);
    foreach (string s in this.backend_argv) argv.append(s);
    
    if (argv_entire == null) {
      // add operation, local, and remote args
      switch (mode) {
      case Operation.Mode.BACKUP:
        argv.append(local_arg);
        argv.append(remote);
        break;
      case Operation.Mode.RESTORE:
        argv.prepend("restore");
        argv.append(remote);
        argv.append(local_arg);
        break;
      case Operation.Mode.STATUS:
        argv.prepend("collection-status");
        argv.append(remote);
        break;
      }
    }
    
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

