/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008,2009 Michael Terry <mike@mterry.name>,
    © 2009 Andrew Fister <temposs@gmail.com>

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

public class Duplicity : Object
{
  public signal void done(bool success, bool cancelled);
  public signal void raise_error(string errstr, string? detail);
  public signal void action_desc_changed(string action);
  public signal void action_file_changed(File file, bool actual);
  public signal void progress(double percent);
  public signal void collection_dates(List<string>? dates);
  public signal void question(string title, string msg);
  public signal void secondary_desc_changed(string msg);
  
  public Operation.Mode original_mode {get; construct;}
  public Operation.Mode mode {get; private set; default = Operation.Mode.INVALID;}
  public bool error_issued {get; private set; default = false;}
  public bool was_stopped {get; private set; default = false;}
  
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
    CLEANUP,
    DELETE,
  }
  protected State state {get; set;}
  
  DuplicityInstance inst;
  
  string remote;
  List<string> backend_argv;
  List<string> saved_argv;
  List<string> saved_envp;
  bool cleaned_up_once = false;
  bool is_full_backup = false;
  
  bool has_progress_total = false;
  double progress_total; // zero, unless we already know limit
  double progress_count; // count of how far we are along in the current instance
  
  bool checked_collection_info = false;
  bool got_collection_info = false;
  struct DateInfo {
    public bool full;
    public TimeVal time;
  }
  List<DateInfo?> collection_info = null;
  
  static const int MINIMUM_FULL = 2;
  bool deleted_files = false;
  int delete_age = 0;
  
  File last_touched_file = null;

  NetworkManager network_manager;

  void network_changed(NetworkManager nm, bool connected)
  {
    if (connected)
      resume();
    else
      pause();
  }

  public Duplicity(Operation.Mode mode) {
    Object(original_mode: mode);
  }
  
  public virtual void start(Backend backend, bool encrypted,
                            List<string>? argv, List<string>? envp)
  {
    // save arguments for calling duplicity again later
    mode = original_mode;
    try {
      this.remote = backend.get_location();
    }
    catch (Error e) {
      raise_error(e.message, null);
      done(false, false);
      return;
    }
    this.backend = backend;
    saved_argv = new List<string>();
    saved_envp = new List<string>();
    backend_argv = new List<string>();
    foreach (string s in argv) saved_argv.append(s);
    foreach (string s in envp) saved_envp.append(s);
    backend.add_argv(Operation.Mode.INVALID, ref backend_argv);
    if (!encrypted)
      backend_argv.append("--no-encryption");
    
    try {
      delete_age = client.get_int(DELETE_AFTER_KEY);
    }
    catch (Error e) {warning("%s\n", e.message);}

    if (!backend.is_native()) {
      network_manager = new NetworkManager();
      network_manager.changed.connect(network_changed);
    }

    if (!restart())
      done(false, false);

    if (network_manager != null && !network_manager.connected) {
      debug("No connection found. Postponing the backup.");
      pause();
    }
  }
  
  public void cancel() {
    var prev_mode = mode;
    mode = Operation.Mode.INVALID;
    
    if (prev_mode == Operation.Mode.BACKUP && state == State.NORMAL) {
      if (cleanup())
        return;
    }
    
    cancel_inst();
  }
  
  public void stop() {
    was_stopped = true;
    if (!DuplicityInfo.get_default().can_resume)
      cancel(); // might as well be clean about it
    else { // just abruptly stop, without a cleanup
      mode = Operation.Mode.INVALID;
      cancel_inst();
    }
  }

  public void pause()
  {
    if (inst != null) {
      inst.pause();
      set_status(_("Paused (no network)"), false);
    }
  }

  public void resume()
  {
    if (inst != null) {
      inst.resume();
      set_saved_status();
    }
  }

  void cancel_inst()
  {
    if (inst == null)
      handle_done(null, false, true);
    else
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
        action_desc = _("Preparing…");
      }
      // If we're backing up, and the version of duplicity supports it, we should
      // first run using --dry-run to get the total size of the backup, to make
      // accurate progress bars.
      else if (!has_progress_total &&
               DuplicityInfo.get_default().has_backup_progress) {
        state = State.DRY_RUN;
        action_desc = _("Preparing…");
        extra_argv.append("--dry-run");
      }
      else {
        if (DuplicityInfo.get_default().has_backup_progress)
          progress(0f);

        /* Set full backup threshold and determine whether we should trigger
           a full backup. */
        if (got_collection_info) {
          Date threshold = DejaDup.get_full_backup_threshold_date();
          Date full_backup = Date();
          foreach (DateInfo info in collection_info) {
            if (info.full)
              full_backup.set_time_val(info.time);
          }
          if (!full_backup.valid() || threshold.compare(full_backup) > 0) {
            is_full_backup = true;
            secondary_desc_changed(_("Creating a fresh backup.  This will take longer than normal."));
          }
        }
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
          local_file.make_directory_with_parents(null);
        }
        catch (Error e) {
          show_error(e.message);
          return false;
        }
        custom_local = local_file.get_path();
        extra_argv.append("--file-to-restore=%s".printf(rel_file_path));
      }
      if (DuplicityInfo.get_default().has_restore_progress)
        progress(0f);
      break;
    }
    
    // Send appropriate description for what we're about to do.  Is often
    // very quickly overridden by a message like "Backing up file X"
    if (action_desc == null)
      action_desc = Operation.mode_to_string(mode);
    set_status(action_desc);
    
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
    
    set_status(_("Cleaning up…"));
    connect_and_start(null, null, cleanup_argv);
    
    return true;
  }
  
  bool delete_excess(int cutoff) {
    if (cutoff < MINIMUM_FULL)
      return false;

    state = State.DELETE;
    var argv = new List<string>();
    argv.append("remove-all-but-n-full");
    argv.append("%d".printf(cutoff));
    argv.append("--force");
    argv.append(this.remote);
    
    set_status(_("Cleaning up…"));
    connect_and_start(null, null, argv);
    
    return true;
  }
  
  void handle_done(DuplicityInstance? inst, bool success, bool cancelled)
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
        cleaned_up_once = true;
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
        else if (success && mode == Operation.Mode.BACKUP) {
          if (delete_files_if_needed())
            return;
        }
        break;
      }
    }
    else if (was_stopped)
      success = true; // we treat stops as success
    
    if (error_issued)
      success = false;
    
    if (!success && !cancelled && !error_issued)
      show_error(_("Failed with an unknown error."));
    
    inst = null;
    done(success, cancelled);
  }
  
  string saved_status;
  File saved_status_file;
  bool saved_status_file_action;
  void set_status(string msg, bool save = true)
  {
    if (save) {
      saved_status = msg;
      saved_status_file = null;
    }
    action_desc_changed(msg);
  }

  void set_status_file(File file, bool action, bool save = true)
  {
    if (save) {
      saved_status = null;
      saved_status_file = file;
      saved_status_file_action = action;
    }
    action_file_changed(file, action);
  }

  void set_saved_status()
  {
    if (saved_status != null)
      set_status(saved_status, false);
    else
      set_status_file(saved_status_file, saved_status_file_action, false);
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
  
  // Should only be called *after* a successful backup
  bool delete_files_if_needed()
  {
    // Check if we need to delete any backups
    // If we got collection info, examine it to see if we should delete old
    // files.
    if (got_collection_info && !deleted_files) {
      // Alright, let's look at collection data
      int full_dates = 0;
      TimeVal prev_time = TimeVal();
      Date prev_date = Date();
      int too_old = 0;
      TimeVal now = TimeVal();
      now.get_current_time();

      Date today = Date();
      today.set_time_val(now);
      
      foreach (DateInfo info in collection_info) {
        if (info.full) {
          if (full_dates > 0) { // Wait until we have a prev_time
            prev_date.set_time_val(prev_time); // compare last incremental backup
            if (prev_date.days_between(today) > delete_age)
              ++too_old;
          }
          ++full_dates;
        }
        prev_time = info.time;
      }
      prev_date.set_time_val(prev_time); // compare last incremental backup
      if (prev_date.days_between(today) > delete_age)
        ++too_old;
      
      // Did we just finished a successful full backup?
      // Collection info won't have our recent backup, because it is done at
      // beginning of backup.
      if (is_full_backup)
        ++full_dates;

      if (too_old > 0 && full_dates > MINIMUM_FULL) {
        // Alright, let's delete those ancient files!
        int cutoff = int.max(MINIMUM_FULL, full_dates - too_old);
        return delete_excess(cutoff);
      }
      
      // If we don't need to delete, pretend we did and move on.
      deleted_files = true;
      return false;
    }
    else
      return false;
  }

  protected static const int ERROR_HOSTNAME_CHANGED = 3;
  protected static const int ERROR_RESTORE_DIR_NOT_FOUND = 19;
  protected static const int ERROR_EXCEPTION = 30;
  protected static const int ERROR_GPG = 31;
  protected static const int INFO_PROGRESS = 2;
  protected static const int INFO_COLLECTION_STATUS = 3;
  protected static const int INFO_DIFF_FILE_NEW = 4;
  protected static const int INFO_DIFF_FILE_CHANGED = 5;
  protected static const int INFO_DIFF_FILE_DELETED = 6;
  protected static const int INFO_PATCH_FILE_WRITING = 7;
  protected static const int INFO_PATCH_FILE_PATCHING = 8;
  protected static const int INFO_SYNCHRONOUS_UPLOAD_BEGIN = 11;
  protected static const int INFO_ASYNCHRONOUS_UPLOAD_BEGIN = 12;
  protected static const int INFO_SYNCHRONOUS_UPLOAD_DONE = 13;
  protected static const int INFO_ASYNCHRONOUS_UPLOAD_DONE = 14;
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
  
  bool ask_question(string t, string m)
  {
    disconnect_inst();
    question(t, m);
    var rv = mode != Operation.Mode.INVALID; // return whether we were canceled
    if (!rv)
      handle_done(null, false, true);
    return rv;
  }

  protected virtual void process_error(string[] firstline, List<string>? data,
                                       string text_in)
  {
    string text = text_in;
    
    // Ignore errors during cleanup.  If they're real, they'll repeat.
    // They might be not-so-real, like the errors one gets when restoring
    // from a backup when not all of the signature files are in your archive
    // dir (which happens when you start using an archive dir in the middle
    // of a backup chain).
    if (state == State.CLEANUP)
      return;
    
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
          text = _("Could not restore ‘%s’: File not found in backup").printf(
                   restore_files.data.get_parse_name());
        break;
      case ERROR_GPG:
        text = _("Bad encryption password.");
        break;
      case ERROR_HOSTNAME_CHANGED:
        if (firstline.length >= 4) {
          if (!ask_question(_("Computer name changed"), _("The existing backup is of a computer named %s, but the current computer’s name is %s.  If this is unexpected, you should backup to a different location.").printf(firstline[2], firstline[3])))
            return;
        }
        // Else just assume that user wants to allow the mismatch...
        // A little troubling but better than not letting user proceed
        saved_argv.append("--allow-source-mismatch");
        if (restart())
          return;
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
      else if (text.str("[Errno 5]") != null && // I/O Error
               last_touched_file != null) {
        if (mode == Operation.Mode.BACKUP)
          show_error(_("Error reading file ‘%s’.").printf(last_touched_file.get_parse_name()));
        else
          show_error(_("Error writing file ‘%s’.").printf(last_touched_file.get_parse_name()));
      }
      else if (text.str("[Errno 28]") != null) { // No space left on device
        string where;
        if (mode == Operation.Mode.BACKUP)
          where = backend.get_location_pretty();
        else
          where = local;
        show_error(_("No space left in %s").printf(where));
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
      case INFO_SYNCHRONOUS_UPLOAD_BEGIN:
      case INFO_ASYNCHRONOUS_UPLOAD_BEGIN:
        if (!backend.is_native())
          set_status(_("Uploading…"));
        break;
      }
    }
  }
  
  void process_diff_file(string file) {
    var gfile = make_file_obj(file);
    last_touched_file = gfile;
    if (gfile.query_file_type(FileQueryInfoFlags.NONE, null) != FileType.DIRECTORY)
      set_status_file(gfile, state != State.DRY_RUN);
  }
  
  void process_patch_file(string file) {
    var gfile = make_file_obj(file);
    last_touched_file = gfile;
    if (gfile.query_file_type(FileQueryInfoFlags.NONE, null) != FileType.DIRECTORY)
      set_status_file(gfile, state != State.DRY_RUN);
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
    var infos = new List<DateInfo?>();
    bool in_chain = false;
    foreach (string line in lines) {
      if (line == "chain-complete" || line.str("chain-no-sig") == line)
        in_chain = true;
      else if (in_chain && line.length > 0 && line[0] == ' ') {
        // OK, appears to be a date line.  Try to parse.  Should look like:
        // ' inc TIMESTR NUMVOLS'.  Since there's a space at the beginning,
        // when we tokenize it, we should expect an extra token at the front.
        string[] tokens = line.split(" ");
        if (tokens.length > 2 && timeval.from_iso8601(tokens[2])) {
          dates.append(tokens[2]);
          
          var info = DateInfo();
          info.time = timeval;
          info.full = tokens[1] == "full";
          infos.append(info);
        }
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
    collection_info = new List<DateInfo?>();
    foreach (DateInfo s in infos)
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
        if (!this.cleaned_up_once)
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

  // Returns volume size in megs
  int get_volsize()
  {
    // Advantages of a smaller value:
    // * takes less temp space
    // * retries of a volume take less time
    // * quicker restore of a particular file (less excess baggage to download)
    // * we get feedback more frequently (duplicity only gives us a progress
    //   report at the end of a volume) -- fixed by reporting when we're uploading
    // Downsides:
    // * less throughput:
    //   * some protocols have large per-file overhead (like sftp)
    //   * the network doesn't have time to ramp up to max tcp transfer speed per
    //     file
    // * lots of files looks ugly to users
    //
    // duplicity's default is 25 (used to be 5).
    //
    // For local filesystems, we'll choose large volsize.
    // For remote FSs, we'll go smaller.
    if (backend.is_native())
      return 30;
    else
      return 10;
  }

  void disconnect_inst()
  {
    if (inst != null) {
      inst.done.disconnect(handle_done);
      inst.message.disconnect(handle_message);
      inst.cancel();
      inst = null;
    }
  }

  void connect_and_start(List<string>? argv_extra = null,
                         List<string>? envp_extra = null,
                         List<string>? argv_entire = null,
                         string? custom_local = null)
  {
    disconnect_inst();

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
        if (is_full_backup)
          argv.prepend("full");
        argv.append("--volsize=%d".printf(get_volsize()));
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

