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
  
  public Gtk.Window toplevel {get; construct;}
  public Operation.Mode mode {get; construct;}
  public bool error_issued {get; private set;}
  
  bool verbose = false;
  
  DuplicityDry dry_run;
  List<string> dry_argv;
  List<string> dry_envp;
  uint dry_total;
  
  public Duplicity(Operation.Mode mode, Gtk.Window? win) {
    this.mode = mode;
    toplevel = win;
  }
  
  public string default_action_desc()
  {
    switch (mode) {
    case Operation.Mode.BACKUP:
      return _("Backing up...");
    case Operation.Mode.RESTORE:
      return _("Restoring...");
    case Operation.Mode.CLEANUP:
      return _("Cleaning up...");
    default:
      return "";
    }
  }
  
  public virtual void start(List<string> argv, List<string>? envp) throws SpawnError
  {
    // If we're backing up, and the version of duplicity supports it, we should
    // first run using --dry-run to get the total size of the backup, to make
    // accurate progress bars.
    if (dry_run == null && mode == Operation.Mode.BACKUP &&
        DuplicityInfo.get_default().has_backup_progress) {
      action_desc_changed(_("Preparing..."));
      
      // save arguments for calling start() on ourselves again later
      dry_argv = new List<string>();
      dry_envp = new List<string>();
      foreach (string s in argv) dry_argv.append(s);
      foreach (string s in envp) dry_envp.append(s);
      dry_total = 0;
      
      dry_run = new DuplicityDry(Operation.Mode.INVALID, toplevel);
      dry_run.done += dry_done;
      dry_run.start(argv, envp);
      
      return;
    }
    
    // Send appropriate description for what we're about to do.  Is often
    // very quickly overridden by a message like "Backing up file X"
    action_desc_changed(default_action_desc());
    
    if (mode == Operation.Mode.CLEANUP &&
        DuplicityInfo.get_default().has_broken_cleanup) {
      done(true, false); // pretend we're naturally done
      return;
    }
    
    var verbose_str = Environment.get_variable("DEJA_DUP_DEBUG");
    if (verbose_str != null && verbose_str.to_int() > 0)
      verbose = true;
    
    // Copy current environment, add custom variables
    var myenv = Environment.list_variables();
    int myenv_len = 0;
    while (myenv[myenv_len] != null)
      ++myenv_len;
    
    var env_len = myenv_len + envp.length();
    string[] real_envp = new string[env_len + 1];
    int i = 0;
    for (; i < myenv_len; ++i)
      real_envp[i] = "%s=%s".printf(myenv[i], Environment.get_variable(myenv[i]));
    foreach (string env in envp)
      real_envp[i++] = env;
    real_envp[i] = null;
    
    // Open pipes to communicate with subprocess
    if (pipe(pipes) != 0) {
      done(false, false);
      return;
    }
    
    argv.append("--verbosity=9");
    
    // Default volsize is 5.  We prefer 1 because:
    // * takes less temp space
    // * retries of a volume take less time
    // * quicker restore of a particular file (less excess baggage to download)
    // * we get feedback more frequently (duplicity only gives us a progress
    //   report at the end of a volume)
    // Downsides:
    // * network throughput might be lower.  Some protocols have large per-file
    //   overhead (like ssh) and the network doesn't have time to ramp up to
    //   max tcp transfer speed per file.
    argv.append("--volsize=1");
    
    // Add always-there arguments
    argv.append("--log-fd=%d".printf(pipes[1]));
    argv.prepend("duplicity");
    
    // Check for ionice to be a good disk citizen
    if (Environment.find_program_in_path("ionice") != null) {
      argv.prepend("-c3"); // idle class
      argv.prepend("ionice");
    }
    
    string cmd = null;
    string[] real_argv = new string[argv.length()];
    i = 0;
    foreach(string a in argv) {
      real_argv[i++] = a;
      if (cmd == null)
        cmd = a;
      else if (a != null)
        cmd = "%s %s".printf(cmd, a);
    }
    debug("Running the following duplicity command: %s\n", cmd);
    
    Process.spawn_async_with_pipes(null, real_argv, real_envp,
                        SpawnFlags.SEARCH_PATH |
                        SpawnFlags.DO_NOT_REAP_CHILD |
                        SpawnFlags.LEAVE_DESCRIPTORS_OPEN |
                        SpawnFlags.STDOUT_TO_DEV_NULL |
                        SpawnFlags.STDERR_TO_DEV_NULL,
                        null, out child_pid, null, null, null);
    
    reader = new IOChannel.unix_new(pipes[0]);
    stanza_id = reader.add_watch(IOCondition.IN, read_stanza);
    close(pipes[1]);
    
    ChildWatch.add(child_pid, spawn_finished);
  }
  
  uint stanza_id;
  Pid child_pid;
  int[] pipes;
  IOChannel reader;
  construct {
    reader = null;
    pipes = new int[2];
    pipes[0] = pipes[1] = -1;
    error_issued = false;
  }
  
  public bool is_started()
  {
    if (dry_run != null)
      return dry_run.is_started();
    else
      return (int)child_pid > 0;
  }
  
  void dry_done(DuplicityDry dry, bool success, bool cancelled)
  {
    if (success == true)
      dry_total = dry.total_bytes;
    
    try {
      if (cancelled)
        done(success, cancelled);
      else
        start(dry_argv, dry_envp);
    }
    catch (Error e) {
      show_error(e.message);
      done(false, false);
    }
    finally {
      dry_run = null;
      dry_argv = null;
      dry_envp = null;
    }
  }
  
  bool read_stanza(IOChannel channel, IOCondition cond)
  {
    string result;
    try {
      IOStatus status;
      List<string> stanza = new List<string>();
      while (true) {
        status = channel.read_line(out result, null, null);
        if (status == IOStatus.NORMAL && result != "\n") {
          if (verbose)
            print("DUPLICITY: %s", result); // result has line ending
          stanza.append(result);
        }
        else
          break;
      }
      
      if (verbose)
        print("\n"); // breather
      
      process_stanza(stanza);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    return true;
  }
  
  // If start is < 0, starts at word.size() - 1.
  static int num_suffix(string word, char ch, long start = -1)
  {
    int rv = 0;
    
    if (start < 0)
      start = word.size() - 1;
    
    for (long i = start; i >= 0; --i, ++rv)
      if (word[i] != ch)
        break;
    
    return rv;
  }
  
  static void split_line(string line, out string[] split)
  {
    var firstsplit = line.split(" ");
    var splitlist = new List<string>();
    
    int i;
    bool in_group = false;
    string group_word = "";
    for (i = 0; firstsplit[i] != null; ++i) {
      string word = firstsplit[i];
      
      if (firstsplit[i+1] == null)
        word.chomp();
      
      // Merge word groupings like 'hello \'goodbye' as one word.
      // Assumes that duplicity isn't a dick and gives us well formed groupings
      // so we only check for apostrophe at beginning and end of words.  We
      // won't crash if duplicity is a dick, but we won't correctly group words.
      if (!in_group && word.has_prefix("\'"))
        in_group = true;
      
      if (in_group) {
        if (word.has_suffix("\'") &&
            // OK, word ends with '...  But is it a *real* ' or a fake one?
            // i.e. is it escaped or not?  Test this by seeing if it has an even
            // number of backslashes before it.
            num_suffix(word, '\\', word.size() - 2) % 2 == 0)
          in_group = false;
        // Else...  If it ends with just a backslash, the backslash was
        // supposed to be for the space.  So just drop it.
        else if (num_suffix(word, '\\') % 2 == 1)
          // Chop off last backslash.
          word = word.substring(0, word.len() - 2);
        
        // get rid of any other escaping backslashes and translate octals
        word = word.compress();
        
        // Now join to rest of group.
        if (group_word == "")
          group_word = word;
        else
          group_word += " " + word;
        
        if (!in_group) {
          // add to list, but drop single quotes
          splitlist.append(group_word.substring(1, group_word.len() - 2));
          group_word = "";
        }
      }
      else
        splitlist.append(word);
    }
    
    // Now make it nice array for ease of random access
    split = new string[splitlist.length()];
    i = 0;
    foreach (string s in splitlist)
      split[i++] = s;
  }
  
  protected static const int ERROR_EXCEPTION = 30;
  protected static const int INFO_PROGRESS = 2;
  protected static const int INFO_DIFF_FILE_NEW = 4;
  protected static const int INFO_DIFF_FILE_CHANGED = 5;
  protected static const int INFO_DIFF_FILE_DELETED = 6;
  protected static const int INFO_PATCH_FILE_WRITING = 7;
  protected static const int INFO_PATCH_FILE_PATCHING = 8;
  
  void process_stanza(List<string> stanza)
  {
    string[] firstline;
    split_line(stanza.data, out firstline);
    
    var keyword = firstline[0];
    switch (keyword) {
    case "ERROR":
      process_error(firstline, stanza);
      break;
    case "INFO":
      process_info(firstline, stanza);
      break;
    }
    
  }
  
  protected virtual void process_error(string[] firstline, List<string> stanza)
  {
    var errorstr = grab_stanza_text(stanza);
    
    if (firstline.length > 1) {
      switch (firstline[1].to_int()) {
      case ERROR_EXCEPTION: // exception
        process_exception(firstline.length > 2 ? firstline[2] : "", errorstr, stanza);
        return;
      }
    }
    
    show_error(errorstr);
  }
  
  void process_exception(string exception, string errorstr, List<string> stanza)
  {
    switch (exception) {
    case "S3ResponseError":
      if (errorstr.str("<Code>InvalidAccessKeyId</Code>") != null)
        show_error(_("Invalid ID"));
      else if (errorstr.str("<Code>SignatureDoesNotMatch</Code>") != null)
        show_error(_("Invalid secret key"));
      break;
    }
    
    // For most, don't do anything. Error string won't be useful to humans, and
    // by not raising it, we'll eventually hit the 'unknown error'
    // message which is slightly better than a giant exception string.
  }
  
  protected virtual void process_info(string[] firstline, List<string> stanza)
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
    
    uint now, total;
    
    if (firstline.length > 2)
      now = firstline[2].to_int();
    else
      return;
    
    if (firstline.length > 3)
      total = firstline[3].to_int();
    else if (dry_total > 0)
      total = dry_total;
    else
      return; // can't do progress without a total
    
    double percent = now / (double)total;
    if (percent > 1)
      percent = 1;
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
  
  string grab_stanza_text(List<string> stanza)
  {
    string text = "";
    foreach (string line in stanza) {
      if (line.has_prefix(". ")) {
        var split = line.split(". ", 2);
        text = "%s%s".printf(text, split[1]);
      }
    }
    return text.chomp();
  }
  
  void spawn_finished(Pid pid, int status)
  {
    if (stanza_id != 0)
      Source.remove(stanza_id);
    
    bool success = Process.if_exited(status) && Process.exit_status(status) == 0;
    bool cancelled = !Process.if_exited(status);
    
    if (reader != null) {
      // Get last reads in before we shut down (needed sometimes, not sure why)
      while (true) {
        IOCondition cond = reader.get_buffer_condition();
        if (cond == IOCondition.IN)
          read_stanza(reader, cond);
        else
          break;
      }
      
      if (Process.if_exited(status)) {
        var exitval = Process.exit_status(status);
        debug("duplicity exited with value %i\n", exitval);
        
        if (exitval != 0) {
          if (!error_issued) {
            show_error(_("Failed with an unknown error."));
          }
        }
      }
      
      try {
        reader.shutdown(false);
      } catch (Error e) {
        warning("%s\n", e.message);
      }
      reader = null;
    }
    
    Process.close_pid(pid);
    
    done(success, cancelled);
  }
  
  public void cancel()
  {
    if (dry_run != null)
      dry_run.cancel();
    else if (is_started())
      kill((int)child_pid, 15);
    else
      done(false, true);
  }
  
  void show_error(string errorstr)
  {
    error_issued = true;
    raise_error(errorstr, null);
  }
}

} // end namespace

