/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008,2009 Michael Terry <mike@mterry.name>

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

public class DuplicityInstance : Object
{
  public signal void done(bool success, bool cancelled);
  public signal void message(string[] control_line, List<string>? data_lines,
                             string user_text);
  
  public bool verbose {get; private set; default = false;}
  
  public virtual void start(List<string> argv_in, List<string>? envp_in) throws SpawnError
  {
    var verbose_str = Environment.get_variable("DEJA_DUP_DEBUG");
    if (verbose_str != null && verbose_str.to_int() > 0)
      verbose = true;
    
    // Open pipes to communicate with subprocess
    if (Posix.pipe(pipes) != 0) {
      done(false, false);
      return;
    }
    
    // Copy current environment, add custom variables
    var myenv = Environment.list_variables();
    int myenv_len = 0;
    while (myenv[myenv_len] != null)
      ++myenv_len;
    
    var env_len = myenv_len + envp_in.length();
    string[] real_envp = new string[env_len + 1];
    int i = 0;
    for (; i < myenv_len; ++i)
      real_envp[i] = "%s=%s".printf(myenv[i], Environment.get_variable(myenv[i]));
    foreach (string env in envp_in)
      real_envp[i++] = env;
    real_envp[i] = null;
    
    List<string> argv = new List<string>();
    foreach (string arg in argv_in)
      argv.append(arg);
    
    argv.append("--verbosity=9");
    
    // Our default volsize is 5M (duplicity's default is now 25M).
    // Advantages of a smaller value:
    // * takes less temp space
    // * retries of a volume take less time
    // * quicker restore of a particular file (less excess baggage to download)
    // * we get feedback more frequently (duplicity only gives us a progress
    //   report at the end of a volume)
    // Downsides:
    // * network throughput might be lower
    // * some protocols have large per-file overhead (like sftp)
    // * the network doesn't have time to ramp up to max tcp transfer speed per
    //   file.
    // * too many files on the backend can lead to not being able to do
    //   anything with duplicity, as ssh (or ftp or others?) can't list all
    //   the files without timing out
    //
    // All told, it would be nice if we could do lower volsize.  If duplicity
    // ever solves the 'too many files' problem, we should go down to volsize
    // 1 or 2.  For now, we'll keep with the default.
    argv.append("--volsize=5");
    
    // Cache signature files
    var cache_dir = Environment.get_user_cache_dir();
    if (cache_dir != null) {
      bool add_dir = false;
      var cache_file = File.new_for_path(cache_dir);
      cache_file = cache_file.get_child(Config.PACKAGE);
      try {
        if (cache_file.make_directory_with_parents(null))
          add_dir = true;
      }
      catch (IOError.EXISTS e) {
        add_dir = true; // ignore
      }
      catch (IOError e) {
        warning("%s\n", e.message);
      }
      if (add_dir)
        argv.append("--archive-dir=" + cache_file.get_path());
    }
    
    // Add always-there arguments
    argv.append("--log-fd=%d".printf(pipes[1]));
    argv.prepend("duplicity");
    
    // Check for ionice to be a good disk citizen
    if (Environment.find_program_in_path("ionice") != null) {
      argv.prepend("-n7"); // lowest priority
      argv.prepend("-c2"); // best-effort class (can't use idle as normal user on <2.6.25)
      argv.prepend("ionice");
    }
    if (Environment.find_program_in_path("nice") != null)
      argv.prepend("nice");
    
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
    
    Process.spawn_async_with_pipes(null, real_argv, real_envp,
                        SpawnFlags.SEARCH_PATH |
                        SpawnFlags.DO_NOT_REAP_CHILD |
                        SpawnFlags.LEAVE_DESCRIPTORS_OPEN |
                        SpawnFlags.STDOUT_TO_DEV_NULL |
                        SpawnFlags.STDERR_TO_DEV_NULL,
                        null, out child_pid, null, null, null);
    
    debug("Running the following duplicity (%i) command: %s\n", (int)child_pid, cmd);
    
    reader = new IOChannel.unix_new(pipes[0]);
    try {
      // Don't use an encoding, filenames may have any old bytes in them
      reader.set_encoding(null);
    }
    catch (IOChannelError e) {} // ignore
    stanza_id = reader.add_watch(IOCondition.IN, read_stanza);
    Posix.close(pipes[1]);
    
    watch_id = ChildWatch.add(child_pid, spawn_finished);
  }
  
  public bool is_started()
  {
    return (int)child_pid > 0;
  }
  
  public void cancel()
  {
    if (is_started())
      kill_child();
    else
      done(false, true);
  }
  
  uint stanza_id;
  uint watch_id;
  Pid child_pid;
  int[] pipes;
  IOChannel reader;
  construct {
    reader = null;
    pipes = new int[2];
    pipes[0] = pipes[1] = -1;
  }
  
  ~DuplicityInstance()
  {
    if (stanza_id != 0)
      Source.remove(stanza_id);
    
    if (watch_id != 0)
      Source.remove(watch_id);
    
    if (is_started()) {
      debug("duplicity (%i) process killed\n", (int)child_pid);
      kill_child();
    }
  }
  
  void kill_child() {
    Posix.kill((Posix.pid_t)child_pid, Posix.SIGKILL);
  }
  
  bool read_stanza(IOChannel channel, IOCondition cond)
  {
    string line;
    try {
      IOStatus status;
      List<string> stanza = new List<string>();
      while (true) {
        status = channel.read_line(out line, null, null);
        if (status == IOStatus.NORMAL && line != "\n") {
          if (verbose)
            print("DUPLICITY: %s", line); // line has line ending
          stanza.append(line);
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
  
  static string validated_string(string s)
  {
    string rv = "";
    weak string p = s;
    char[] charstr = new char[6];
    
    while (p[0] != 0) {
      unichar ch = p.get_char_validated();
      if (ch == (uint)(-1) || ch == (uint)(-2)) {
        rv += "\xef\xbf\xbd"; // the 'unknown character' character in utf-8
        p = p.offset(1);
      }
      else {
        ch.to_utf8((string)charstr);
        rv += (string)charstr;
        p = p.next_char();
      }
    }
    
    return rv;
  }
  
  static string compress_string(string s_in)
  {
    char[] rv = new char[s_in.size()+1];
    weak char[] s = (char[])s_in;
    
    int i = 0, j = 0;
    while (s[i] != 0) {
      if (s[i] == '\\' && s[i+1] != 0) {
        bool bare_escape = false;
        
        switch (s[i+1]) {
        case 'b': rv[j++] = '\b'; i += 2; break;
        case 'f': rv[j++] = '\014'; i += 2; break;
        case 't': rv[j++] = '\t'; i += 2; break;
        case 'n': rv[j++] = '\n'; i += 2; break;
        case 'r': rv[j++] = '\r'; i += 2; break;
        case 'v': rv[j++] = '\013'; i += 2; break;
        case 'a': rv[j++] = '\007'; i += 2; break;
        case 'x':
          // start of a hex number
          if (s[i+2] != 0 && s[i+3] != 0) {
            char[] tmpstr = new char[3];
            tmpstr[0] = s[i+2];
            tmpstr[1] = s[i+3];
            var val = ((string)tmpstr).to_ulong(null, 16);
            rv[j++] = (char)val;
            i += 4;
          }
          else
            bare_escape = true;
          break;
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
          // start of an octal number
          if (s[i+2] != 0 && s[i+3] != 0 && s[i+4] != 0) {
            char[] tmpstr = new char[4];
            tmpstr[0] = s[i+2];
            tmpstr[1] = s[i+3];
            tmpstr[2] = s[i+4];
            var val = ((string)tmpstr).to_ulong(null, 8);
            rv[j++] = (char)val;
            i += 5;
          }
          else
            bare_escape = true;
          break;
        default:
          bare_escape = true; break;
        }
        if (bare_escape) {
          rv[j++] = s[i+1]; i+=2;
        }
      }
      else
        rv[j++] = s[i++];
    }
    
    return (string)rv;
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
        word = compress_string(word);
        
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
  
  void process_stanza(List<string> stanza)
  {
    string[] control_line;
    split_line(stanza.data, out control_line);
    
    var data = grab_stanza_data(stanza);
    
    var text = grab_stanza_text(stanza);
    
    message(control_line, data, text);
  }
  
  List<string> grab_stanza_data(List<string> stanza)
  {
    var list = new List<string>();
    stanza = stanza.next; // skip first control line
    foreach (string line in stanza) {
      if (!line.has_prefix(". "))
        list.append(validated_string(line.chomp())); // drop endline
    }
    return list;
  }
  
  string grab_stanza_text(List<string> stanza)
  {
    string text = "";
    foreach (string line in stanza) {
      if (line.has_prefix(". ")) {
        var split = line.split(". ", 2);
        text = "%s%s".printf(text, validated_string(split[1]));
      }
    }
    return text.chomp();
  }
  
  void spawn_finished(Pid pid, int status)
  {
    // Reference ourselves, because when processing stanza we have not
    // yet gotten to below, whoever owns us might unref us in the middle of
    // this function, and we don't want to die immediately.  Wait until the
    // end.
    ref();
    
    if (stanza_id != 0)
      Source.remove(stanza_id);
    stanza_id = 0;
    watch_id = 0;
    
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
        debug("duplicity (%i) exited with value %i\n", (int)pid, exitval);
      }
      else {
        debug("duplicity (%i) process killed\n", (int)pid);
      }
      
      try {
        reader.shutdown(false);
      } catch (Error e) {
        warning("%s\n", e.message);
      }
      reader = null;
    }
    
    Process.close_pid(pid);
    child_pid = (Pid)0;
    
    done(success, cancelled);
    unref();
  }
}

} // end namespace

