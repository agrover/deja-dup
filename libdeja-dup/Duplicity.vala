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

public class Duplicity : Object
{
  public signal void done(bool success, bool cancelled);
  public signal void raise_error(string errstr, string? detail);
  public signal void action_desc_changed(string action);
  
  public Gtk.Window toplevel {get; construct;}
  
  bool verbose = false;
  
  public Duplicity(Gtk.Window? win) {
    toplevel = win;
  }
  
  public void start(List<string> argv, List<string>? envp) throws SpawnError
  {
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
  bool error_issued;
  construct {
    reader = null;
    pipes = new int[2];
    pipes[0] = pipes[1] = -1;
    error_issued = false;
  }
  
  public bool is_started()
  {
    return (int)child_pid > 0;
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
  
  static const int ERROR_EXCEPTION = 30;
  static const int INFO_DIFF_FILE_NEW = 4;
  static const int INFO_DIFF_FILE_CHANGED = 5;
  static const int INFO_DIFF_FILE_DELETED = 6;
  static const int INFO_PATCH_FILE_WRITING = 7;
  static const int INFO_PATCH_FILE_PATCHING = 8;
  
  void process_stanza(List<string> stanza)
  {
    string[] firstline;
    split_line(stanza.data, out firstline);
    
    var keyword = firstline[0];
    switch (keyword) {
    case "ERROR":
      var errorstr = grab_stanza_text(stanza);
      
      if (firstline.length > 1) {
        switch (firstline[1].to_int()) {
        case ERROR_EXCEPTION: // exception
          process_exception(firstline.length > 2 ? firstline[2] : "", errorstr, stanza);
          return;
        }
      }
      
      show_error(errorstr);
      break;
    case "INFO":
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
        }
      }
      break;
    }
    
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
  
  void process_diff_file(string file) {
    action_desc_changed(_("Backing up %s").printf(make_filename(file)));
  }
  
  void process_patch_file(string file) {
    action_desc_changed(_("Restoring %s").printf(make_filename(file)));
  }
  
  string make_filename(string file)
  {
    // All files are relative to root.
    File root = File.new_for_path("/");
    File full = root.resolve_relative_path(file);
    return full.get_path();
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
    if (is_started())
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

