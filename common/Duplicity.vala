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

public class Duplicity : Object
{
  /*
   * Vala implementation of various methods for accessing duplicity
   *
   * Vala implementation of various methods for accessing duplicity from
   * vala withot the need of manually running duplicity command.
   */

  public signal void done(bool success, bool cancelled);
  public signal void raise_error(string errstr, string? detail);
  public signal void action_desc_changed(string action);
  public signal void action_file_changed(File file, bool actual);
  public signal void progress(double percent);
  /*
   * Signal emitted when collection dates are retrieved from duplicity
   */
  public signal void collection_dates(List<string>? dates);
  public signal void listed_current_files(string date, string file);
  public signal void question(string title, string msg);
  public signal void is_full(bool first);
  public signal void bad_encryption_password();
  
  public Operation.Mode original_mode {get; construct;}
  public Operation.Mode mode {get; private set; default = Operation.Mode.INVALID;}
  public bool error_issued {get; private set; default = false;}
  public bool was_stopped {get; private set; default = false;}
  
  public File local {get; set;}
  public Backend backend {get; set;}
  public List<File> includes;
  public List<File> excludes;
  public bool use_progress {get; set; default = true;}
  public string encrypt_password {private get; set;}
  
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
    CHECK_CONTENTS, // used when restoring, and we need to list /home
    CLEANUP,
    DELETE,
  }
  protected State state {get; set;}
  
  DuplicityInstance inst;
  
  string remote;
  List<string> backend_argv;
  List<string> saved_argv;
  List<string> saved_envp;
  bool is_full_backup = false;
  bool cleaned_up_once = false;
  bool needs_root = false;
  
  bool has_progress_total = false;
  uint64 progress_total; // zero, unless we already know limit
  uint64 progress_count; // count of how far we are along in the current instance
  
  static File slash;
  static File slash_root;
  static File slash_home;
  static File slash_home_me;
  
  bool has_checked_contents = false;
  bool has_non_home_contents = false;
  List<File> homes = new List<File>();
  
  bool checked_collection_info = false;
  bool got_collection_info = false;
  struct DateInfo {
    public bool full;
    public TimeVal time;
  }
  List<DateInfo?> collection_info = null;
  
  bool checked_backup_space = false;

  static const int MINIMUM_FULL = 2;
  bool deleted_files = false;
  int delete_age = 0;
  
  File last_touched_file = null;

  void network_changed()
  {
    if (Network.get().connected)
      resume();
    else
      pause(_("Paused (no network)"));
  }

  public Duplicity(Operation.Mode mode) {
    Object(original_mode: mode);
  }
  
  construct {
    if (slash == null) {
      slash = File.new_for_path("/");
      slash_root = File.new_for_path("/root");
      slash_home = File.new_for_path("/home");
      slash_home_me = File.new_for_path(Environment.get_home_dir());
    }
  }
  
  public virtual void start(Backend backend,
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
    
    if (mode == Operation.Mode.BACKUP)
      process_include_excludes();
    
    var settings = get_settings();
    delete_age = settings.get_int(DELETE_AFTER_KEY);

    if (!restart())
      done(false, false);

    if (!backend.is_native()) {
      Network.get().notify["connected"].connect(network_changed);
      if (!Network.get().connected) {
        debug("No connection found. Postponing the backup.");
        pause(_("Paused (no network)"));
      }
    }
  }

  // This will treat a < b iff a is 'lower' in the file tree than b
  int cmp_prefix(File? a, File? b)
  {
    if (a == null && b == null)
      return 0;
    else if (b == null || a.has_prefix(b))
      return -1;
    else if (a == null || b.has_prefix(a))
      return 1;
    else
      return 0;
  }

  void expand_links_in_file(File file, ref List<File> all, bool include, List<File>? seen = null)
  {
    // For symlinks, we want to add the link and its target to the list.
    // Normally, duplicity ignores targets, and this is fine and expected
    // behavior.  But if the user explicitly requested a directory with a 
    // symlink in it's path, they expect a follow-through.
    // If a symlink is anywhere above the directory specified by the user,
    // duplicity will stop at that symlink and only backup the broken link.
    // So we try to work around that behavior by checking for symlinks and only
    // passing duplicity symlinks as leaf elements.
    //
    // This will be much easier if we approach it from the root down.  So
    // walk back towards root, keeping track of each piece as we go.
    List<string> pieces = new List<string>();
    File iter = file, parent;
    while ((parent = iter.get_parent()) != null) {
      pieces.prepend(parent.get_relative_path(iter));
      iter = parent;
    }

    try {
      File so_far = slash;
      foreach (weak string piece in pieces) {
        parent = so_far;
        so_far = parent.resolve_relative_path(piece);
        var info = so_far.query_info(FILE_ATTRIBUTE_STANDARD_IS_SYMLINK + "," +
                                     FILE_ATTRIBUTE_STANDARD_SYMLINK_TARGET,
                                     FileQueryInfoFlags.NOFOLLOW_SYMLINKS, 
                                     null);
        if (info.get_is_symlink()) {
          // Check if we've seen this before (i.e. are we in a loop?)
          if (seen.find_custom(so_far, (a, b) => {
                return (a != null && b != null && a.equal(b)) ? 0 : 1;}) != null)
            return; // stop here

          if (include)
            all.prepend(so_far); // back up symlink as a leaf element of its path

          // Recurse on the new file (since it could point at a completely
          // new place, which has its own symlinks in its hierarchy, so we need
          // to check the whole thing over again).

          var symlink_target = info.get_symlink_target();
          File full_target;
          if (Path.is_absolute(symlink_target))
            full_target = File.new_for_path(symlink_target);
          else
            full_target = parent.resolve_relative_path(symlink_target);

          // Now add the rest of the undone pieces
          var remaining = so_far.get_relative_path(file);
          if (remaining != null)
            full_target = full_target.resolve_relative_path(remaining);

          if (include)
            all.remove(file); // may fail if it's not there, which is fine

          seen.prepend(so_far);

          expand_links_in_file(full_target, ref all, include, seen);
          return;
        }
      }

      // Survived symlink gauntlet, add it to list if this is not the original
      // request (i.e. if this is the final target of a symlink chain)
      if (seen != null)
        all.prepend(file);
    }
    catch (IOError.NOT_FOUND e) {
      // Don't bother keeping this file in the list
      all.remove(file);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }

  void expand_links_in_list(ref List<File> all, bool include)
  {
    var all2 = all.copy();
    foreach (File file in all2)
      expand_links_in_file(file, ref all, include);
  }

  void process_include_excludes()
  {
    expand_links_in_list(ref includes, true);
    expand_links_in_list(ref excludes, false);

    // We need to make sure that the most specific includes/excludes will
    // be first in the list (duplicity uses only first matched dir).  Includes
    // will be preferred if the same dir is present in both lists.
    includes.sort((CompareFunc)cmp_prefix);
    excludes.sort((CompareFunc)cmp_prefix);

    foreach (File i in includes) {
      var excludes2 = excludes.copy();
      foreach (File e in excludes2) {
        if (e.has_prefix(i)) {
          saved_argv.append("--exclude=" + e.get_path());
          excludes.remove(e);
        }
      }
      saved_argv.append("--include=" + i.get_path());
      //if (!i.has_prefix(slash_home_me))
      //  needs_root = true;
    }
    foreach (File e in excludes) {
      saved_argv.append("--exclude=" + e.get_path());
    }

    saved_argv.append("--exclude=**");
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

  public void pause(string? reason)
  {
    if (inst != null) {
      inst.pause();
      if (reason != null)
        set_status(reason, false);
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
    disconnect_inst();
    handle_done(null, false, true);
  }

  bool restart()
  {
    state = State.NORMAL;
    
    if (mode == Operation.Mode.INVALID)
      return false;
    
    var extra_argv = new List<string>();
    string action_desc = null;
    File custom_local = null;
    
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
      else if (use_progress && !has_progress_total &&
               DuplicityInfo.get_default().has_backup_progress) {
        state = State.DRY_RUN;
        action_desc = _("Preparing…");
        extra_argv.append("--dry-run");
      }
      else if (!checked_backup_space) {
        check_backup_space();
        return true;
      }
      else {
        if (has_progress_total)
          progress(0f);
      }
      
      break;
    case Operation.Mode.RESTORE:
      if (!has_checked_contents) {
        mode = Operation.Mode.LIST;
        state = State.CHECK_CONTENTS;
        action_desc = _("Preparing…");
      }
      else {
        // OK, do we have multiple, one, or no home dirs?
        // Only want to bother doing anything if one.  If one, we rename it's
        // home dir to the current user's home dir (i.e. they backed up on one
        // machine as 'alice' and restored on a machine as 'bob').
        if (homes.length() > 1)
          has_non_home_contents = true;
        else if (homes.length() == 1) {
          if (DuplicityInfo.get_default().has_rename_arg) {
            var old_home = homes.data;
            var new_home = slash_home_me;
            if (!old_home.equal(new_home)) {
              extra_argv.append("--rename");
              extra_argv.append(slash.get_relative_path(old_home));
              extra_argv.append(slash.get_relative_path(new_home));
            }
          }
          else if (!homes.data.has_prefix(slash_home_me))
            has_non_home_contents = true;
        }
        
        if (restore_files != null) {
          // Just do first one.  Others will come when we're done
          
          // make path to specific restore file, since duplicity will just
          // drop the file exactly where you ask it
          var local_file = make_local_rel_path(restore_files.data);
          if (local_file == null) {
            // Was not even a file path (maybe something goofy like computer://)
            show_error(_("Could not restore ‘%s’: Not a valid file location").printf(
                         (restore_files.data as File).get_parse_name()));
            return false;
          }

          if (!local_file.has_prefix(slash_home_me))
            needs_root = true;
          
          try {
            // won't have correct permissions...
            local_file.make_directory_with_parents(null);
          }
          catch (IOError.EXISTS e) {
            // ignore
          }
          catch (Error e) {
            show_error(e.message);
            return false;
          }
          custom_local = local_file;
          
          var rel_file_path = slash.get_relative_path(restore_files.data);
          extra_argv.append("--file-to-restore=%s".printf(rel_file_path));
        }
        else {
          if (has_non_home_contents && !this.local.has_prefix(slash_home_me))
            needs_root = true;
        }
        
        if (DuplicityInfo.get_default().has_restore_progress)
          progress(0f);
      }
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
  
  File? make_local_rel_path(File file)
  {
    string rel_file_path = slash.get_relative_path(file);
    if (rel_file_path == null)
      return null;
    return local.resolve_relative_path(rel_file_path);
  }
  
  async void check_backup_space()
  {
    checked_backup_space = true;

    if (!has_progress_total) {
      if (!restart())
        done(false, false);
      return;
    }

    var free = yield backend.get_space();
    var total = yield backend.get_space(false);
    if (total < progress_total) {
        // Tiny backup location.  Suggest they get a larger one.
        show_error(_("Backup location is too small.  Try using one with more space."));
        return;
    }

    if (free < progress_total) {
      if (got_collection_info) {
        // Alright, let's look at collection data
        int full_dates = 0;
        foreach (DateInfo info in collection_info) {
          if (info.full)
            ++full_dates;
        }
        if (full_dates > 1) {
          delete_excess(full_dates - 1);
          // don't set checked_backup_space, we want to be able to do this again if needed
          checked_backup_space = false;
          checked_collection_info = false; // get info again
          return;
        }
      }
      else {
        show_error(_("Backup location does not have enough free space."));
        return;
      }
    }
    
    if (!restart())
      done(false, false);
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
  
  void delete_excess(int cutoff) {
    state = State.DELETE;
    var argv = new List<string>();
    argv.append("remove-all-but-n-full");
    argv.append("%d".printf(cutoff));
    argv.append("--force");
    argv.append(this.remote);
    
    set_status(_("Cleaning up…"));
    connect_and_start(null, null, argv);
    
    return;
  }
  
  bool can_ignore_error()
  {
    // Ignore errors during cleanup.  If they're real, they'll repeat.
    // They might be not-so-real, like the errors one gets when restoring
    // from a backup when not all of the signature files are in your archive
    // dir (which happens when you start using an archive dir in the middle
    // of a backup chain).
    return state == State.CLEANUP || state == State.DELETE;
  }

  void handle_done(DuplicityInstance? inst, bool success, bool cancelled)
  {
    if (can_ignore_error())
      success = true;

    if (!cancelled && success) {
      switch (state) {
      case State.DRY_RUN:
        has_progress_total = true;
        progress_total = progress_count; // save max progress for next run
        if (restart())
          return;
        break;
      
      case State.DELETE:
        if (restart()) // In case we were interrupting normal flow
          return;
        break;
      
      case State.CLEANUP:
        cleaned_up_once = true;
        if (restart()) // restart in case cleanup was interrupting normal flow
          return;
        
        // Else, we probably started cleaning up after a cancel.  Just continue
        // that cancels
        cancelled = true;
        break;
      
      case State.STATUS:
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
            is_full(!full_backup.valid());
          }
        }

        if (restart())
          return;
        break;
      
      case State.CHECK_CONTENTS:
        has_checked_contents = true;
        mode = Operation.Mode.RESTORE;
        
        if (restart())
          return;
        break;
      
      case State.NORMAL:
        if (mode == Operation.Mode.RESTORE && restore_files != null) {
          _restore_files.delete_link(_restore_files);
          if (restore_files != null) {
            if (restart())
              return;
          }
        }
        else if (mode == Operation.Mode.BACKUP) {
          mode = Operation.Mode.INVALID; // mark 'done' so when we delete, we don't restart
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
    if (delete_age == 0) {
      deleted_files = true;
      return false;
    }
    
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
        delete_excess(cutoff);
        return true;
      }
      
      // If we don't need to delete, pretend we did and move on.
      deleted_files = true;
      return false;
    }
    else
      return false;
  }

  protected static const int ERROR_GENERIC = 1;
  protected static const int ERROR_HOSTNAME_CHANGED = 3;
  protected static const int ERROR_RESTORE_DIR_NOT_FOUND = 19;
  protected static const int ERROR_EXCEPTION = 30;
  protected static const int ERROR_GPG = 31;
  protected static const int ERROR_BACKEND = 50;
  protected static const int ERROR_BACKEND_PERMISSION_DENIED = 51;
  protected static const int ERROR_BACKEND_NOT_FOUND = 52;
  protected static const int ERROR_BACKEND_NO_SPACE = 53;
  protected static const int INFO_PROGRESS = 2;
  protected static const int INFO_COLLECTION_STATUS = 3;
  protected static const int INFO_DIFF_FILE_NEW = 4;
  protected static const int INFO_DIFF_FILE_CHANGED = 5;
  protected static const int INFO_DIFF_FILE_DELETED = 6;
  protected static const int INFO_PATCH_FILE_WRITING = 7;
  protected static const int INFO_PATCH_FILE_PATCHING = 8;
  protected static const int INFO_FILE_STAT = 10;
  protected static const int INFO_SYNCHRONOUS_UPLOAD_BEGIN = 11;
  protected static const int INFO_ASYNCHRONOUS_UPLOAD_BEGIN = 12;
  protected static const int INFO_SYNCHRONOUS_UPLOAD_DONE = 13;
  protected static const int INFO_ASYNCHRONOUS_UPLOAD_DONE = 14;
  protected static const int WARNING_ORPHANED_SIG = 2;
  protected static const int WARNING_UNNECESSARY_SIG = 3;
  protected static const int WARNING_UNMATCHED_SIG = 4;
  protected static const int WARNING_INCOMPLETE_BACKUP = 5;
  protected static const int WARNING_ORPHANED_BACKUP = 6;

  bool restarted_without_cache = false;
  bool restart_without_cache()
  {
    if (restarted_without_cache)
      return false;

    restarted_without_cache = true;

    string dir = Environment.get_user_cache_dir();
    if (dir == null)
      return false;

    var cachedir = Path.build_filename(dir, Config.PACKAGE);
    var del = new RecursiveDelete(File.new_for_path(cachedir));
    del.start();
    return restart();
  }

  void handle_exit(int code)
  {
    // Duplicity has a habit of dying and returning 1 without sending an error
    // if there was some unexpected issue with its cached metadata.  It often
    // goes away if you delete ~/.cache/deja-dup and try again.  This issue
    // happens often enough that we do that for the user here.  It should be
    // safe to do this, as the cache is not necessary for operation, only
    // a performance improvement.
    if (DuplicityInfo.get_default().guarantees_error_codes &&
        code == ERROR_GENERIC && !error_issued) {
      restart_without_cache();
    }
  }

  void handle_message(DuplicityInstance inst, string[] control_line,
                      List<string>? data_lines, string user_text)
  {
    /*
     * Based on duplicity's output handle message as either process data as error, info or warning
     */
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
    
    if (can_ignore_error())
      return;
    
    if (firstline.length > 1) {
      switch (int.parse(firstline[1])) {
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
        bad_encryption_password(); // notify upper layers, if they want to do anything
        text = _("Bad encryption password.");
        break;

      case ERROR_HOSTNAME_CHANGED:
        if (firstline.length >= 4) {
          if (!ask_question(_("Computer name changed"), _("The existing backup is of a computer named %s, but the current computer’s name is %s.  If this is unexpected, you should back up to a different location.").printf(firstline[2], firstline[3])))
            return;
        }
        // Else just assume that user wants to allow the mismatch...
        // A little troubling but better than not letting user proceed
        saved_argv.append("--allow-source-mismatch");
        if (restart())
          return;
        break;

      case ERROR_BACKEND_PERMISSION_DENIED:
        if (firstline.length >= 5 && firstline[2] == "put") {
          var file = make_file_obj(firstline[4]);
          text = _("Permission denied when trying to create ‘%s’.").printf(file.get_parse_name());
        }
        if (firstline.length >= 5 && firstline[2] == "get") {
          var file = make_file_obj(firstline[3]); // assume error is on backend side
          text = _("Permission denied when trying to read ‘%s’.").printf(file.get_parse_name());
        }
        else if (firstline.length >= 4 && firstline[2] == "list") {
          var file = make_file_obj(firstline[3]);
          text = _("Permission denied when trying to read ‘%s’.").printf(file.get_parse_name());
        }
        else if (firstline.length >= 4 && firstline[2] == "delete") {
          var file = make_file_obj(firstline[3]);
          text = _("Permission denied when trying to delete ‘%s’.").printf(file.get_parse_name());
        }
        break;

      case ERROR_BACKEND_NOT_FOUND:
        if (firstline.length >= 4) {
          var file = make_file_obj(firstline[3]);
          text = _("Backup location ‘%s’ does not exist.").printf(file.get_parse_name());
        }
        break;

      case ERROR_BACKEND_NO_SPACE:
        if (firstline.length >= 5) {
          text = _("No space left.");
        }
        break;
      }
    }
    
    show_error(text);
  }
  
  void process_exception(string exception, string text)
  {
    switch (exception) {
    case "S3ResponseError":
      if (text.contains("<Code>InvalidAccessKeyId</Code>"))
        show_error(_("Invalid ID."));
      else if (text.contains("<Code>SignatureDoesNotMatch</Code>"))
        show_error(_("Invalid secret key."));
      else if (text.contains("<Code>NotSignedUp</Code>"))
        show_error(_("Your Amazon Web Services account is not signed up for the S3 service."));
      break;
    case "S3CreateError":
      if (text.contains("<Code>BucketAlreadyExists</Code>")) {
        if (((BackendS3)backend).bump_bucket()) {
          try {
            remote = backend.get_location();
            if (restart())
              return;
          }
          catch (Error e) {warning("%s\n", e.message);}
        }
        
        show_error(_("S3 bucket name is not available."));
      }
      break;
    case "IOError":
      if (text.contains("GnuPG"))
        show_error(_("Bad encryption password."));
      else if (text.contains("[Errno 5]") && // I/O Error
               last_touched_file != null) {
        if (mode == Operation.Mode.BACKUP)
          show_error(_("Error reading file ‘%s’.").printf(last_touched_file.get_parse_name()));
        else
          show_error(_("Error writing file ‘%s’.").printf(last_touched_file.get_parse_name()));
      }
      else if (text.contains("[Errno 28]")) { // No space left on device
        string where = null;
        if (mode == Operation.Mode.BACKUP) {
          try {
            where = backend.get_location_pretty();
          }
          catch (Error e) {warning("%s\n", e.message);}
        }
        else
          where = local.get_path();
        if (where == null)
          show_error(_("No space left."));
        else
          show_error(_("No space left in ‘%s’.").printf(where));
      }
      else if (text.contains("CRC check failed")) { // bug 676767
        if (restart_without_cache())
          return;
      }
      else {
        // Very possibly a FAT file system that can't handle the colons that 
        // duplicity likes to use.  Try again with --short-filenames
        // But first make sure we aren't already doing that.
        // Happens on backup only.
        if (!DuplicityInfo.get_default().new_time_format &&
            restart_with_short_filenames_if_needed())
          return;
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
        return;
      show_error(_("No backup files found"));
      break;
    case "AssertionError":
      // Sometimes if an incremental backup is cancelled then tried again,
      // duplicity will emit an "time not moving forward" assertion.  Clearing
      // the cache will solve it.  This message is not localized in duplicity.
      if (text.contains("time not moving forward at appropriate pace")) {
        if (restart_without_cache())
          return;
      }
      break;
    }
    
    // For most, don't do anything special.  Show generic 'unknown error'
    // message, but provide the exception text for better bug reports.
    // Plus, sometimes it may clue the user in to what's wrong.
    // But first, try to restart without a cache, since that seems to quite
    // frequently fix odd metadata errors with duplicity.  If we hit an error
    // a second time, we'll show the unknown error message.
    if (!error_issued && !restart_without_cache())
      show_error(_("Failed with an unknown error."), text);
  }
  
  protected virtual void process_info(string[] firstline, List<string>? data,
                                      string text)
  {
    /*
     * Pass message to appropriate function considering the type of output
     */
    if (firstline.length > 1) {
      switch (int.parse(firstline[1])) {
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
      case INFO_FILE_STAT:
        process_file_stat(firstline[2], firstline[3], data, text);
        break;
      }
    }
  }
  
  void process_file_stat(string date, string file, List<string> data, string text)
  {
    if (mode != Operation.Mode.LIST)
      return;
    if (state == State.CHECK_CONTENTS) {
      var gfile = make_file_obj(file);
      if (gfile.equal(slash_root) ||
          (gfile.get_parent() != null && gfile.get_parent().equal(slash_home)))
        homes.append(gfile);
      if (!has_non_home_contents &&
          !gfile.equal(slash) &&
          !gfile.equal(slash_home) &&
          !gfile.has_prefix(slash_home))
        has_non_home_contents = true;
    }
    listed_current_files(date, file);
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
      this.progress_count = uint64.parse(firstline[2]);
    else
      return;
    
    if (firstline.length > 3)
      total = double.parse(firstline[3]);
    else if (this.progress_total > 0)
      total = this.progress_total;
    else
      return; // can't do progress without a total
    
    double percent = (double)this.progress_count / total;
    if (percent > 1)
      percent = 1;
    if (percent < 0) // ???
      percent = 0;
    progress(percent);
  }
  
  File make_file_obj(string file)
  {
    // All files are relative to root.
    return slash.resolve_relative_path(file);
  }
  
  void process_collection_status(List<string>? lines)
  {
    /*
     * Collect output of collection status and return list of dates as strings via a signal
     *
     * Duplicity returns collection status as a bunch of lines, some of which are
     * indented which contain information about specific chains. We gather
     * this all up and report back to caller via a signal.
     * We're really only interested in the list of entries in the complete chain.
     */
    
    var timeval = TimeVal();
    var dates = new List<string>();
    var infos = new List<DateInfo?>();
    bool in_chain = false;
    foreach (string line in lines) {
      if (line == "chain-complete" || line.index_of("chain-no-sig") == 0)
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
      switch (int.parse(firstline[1])) {
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
      return 50;
    else
      return 25;
  }

  void disconnect_inst()
  {
    /* Disconnect signals and cancel call to duplicity instance */
    if (inst != null) {
      inst.done.disconnect(handle_done);
      inst.message.disconnect(handle_message);
      inst.exited.disconnect(handle_exit);
      inst.cancel();
      inst = null;
    }
  }

  void connect_and_start(List<string>? argv_extra = null,
                         List<string>? envp_extra = null,
                         List<string>? argv_entire = null,
                         File? custom_local = null)
  { 
    /*
     * For passed arguments start a new duplicity instance, set duplicity in the right mode and execute command
     */
    /* Disconnect instance */
    disconnect_inst();
    
    /* Start new duplicity instance */
    inst = new DuplicityInstance();
    inst.done.connect(handle_done);

    /* As duplicity's data is returned via a signal, handle_message begins post-raw stream processing */
    inst.message.connect(handle_message);

    /* When duplicity exits, we may be also interested in its return code */
    inst.exited.connect(handle_exit);

    /* Set arguments for call to duplicity */
    weak List<string> master_argv = argv_entire == null ? saved_argv : argv_entire;
    weak File local_arg = custom_local == null ? local : custom_local;
    
    var argv = new List<string>();
    foreach (string s in master_argv) argv.append(s);
    foreach (string s in argv_extra) argv.append(s);
    foreach (string s in this.backend_argv) argv.append(s);

    /* Set duplicity into right mode */
    if (argv_entire == null) {
      // add operation, local, and remote args
      switch (mode) {
      case Operation.Mode.BACKUP:
        if (is_full_backup)
          argv.prepend("full");
        argv.append("--volsize=%d".printf(get_volsize()));
        argv.append(local_arg.get_path());
        argv.append(remote);
        break;
      case Operation.Mode.RESTORE:
        argv.prepend("restore");
        argv.append("--force");
        argv.append(remote);
        argv.append(local_arg.get_path());
        break;
      case Operation.Mode.STATUS:
        argv.prepend("collection-status");
        argv.append(remote);
        break;
      case Operation.Mode.LIST:
        argv.prepend("list-current-files");
        argv.append(remote);
        break;
      }
    }

    /* Set environmental parameters */
    var envp = new List<string>();
    foreach (string s in saved_envp) envp.append(s);
    foreach (string s in envp_extra) envp.append(s);

    if (encrypt_password == null || encrypt_password == "") {
      argv.append("--no-encryption");
      envp.append("PASSPHRASE="); // duplicity sometimes asks for a passphrase when it doesn't need it (during cleanup), so this stops it from prompting the user and us getting an exception as a result
    }
    else {
      envp.append("PASSPHRASE=%s".printf(encrypt_password));
    }

    /* Start duplicity instance */
    try {
      inst.start(argv, envp, needs_root);
    }
    catch (Error e) {
      show_error(e.message);
      done(false, false);
    }
  }
}

} // end namespace

