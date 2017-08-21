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

internal class DuplicityInstance : Object
{
  public signal void done(bool success, bool cancelled);
  public signal void exited(int code);
  public signal void message(string[] control_line, List<string>? data_lines,
                             string user_text);
  
  public bool verbose {get; private set; default = false;}
  public string forced_cache_dir {get; set; default = null;}
  
  public async void start(List<string> argv_in, List<string>? envp_in,
                          bool as_root = false)
  {
    try {
      /* Make deep copies of the lists, so if our caller doesn't yield, the
         lists won't be invalidated. */
      var argv = new List<string>();
      foreach (var arg in argv_in)
        argv.append(arg);
      var envp = new List<string>();
      foreach (var env in envp_in)
        envp.append(env);
      if (!yield start_internal(argv, envp, as_root))
        done(false, false);
    }
    catch (Error e) {
      // Fake a generic message from duplicity
      message({"ERROR", "1"}, null, e.message);
      done(false, false);
    }
  }

  async bool start_internal(List<string> argv_in, List<string>? envp_in,
                            bool as_root) throws Error
  {
    var verbose_str = Environment.get_variable("DEJA_DUP_DEBUG");
    if (verbose_str != null && int.parse(verbose_str) > 0)
      verbose = true;

    if (as_root) {
      var settings = DejaDup.get_settings();
      if (!settings.get_boolean(DejaDup.ROOT_PROMPT_KEY))
        as_root = false;
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

    // It's possible for --use-agent to be on by default (as it is in Ubuntu).
    // But we never want an agent, and it's a possible point of failure (e.g.
    // bug 681002), so just make sure it's disabled.
    argv.append("--gpg-options=--no-use-agent");

    // Cache signature files
    var cache_dir = forced_cache_dir;
    if (cache_dir == null)
      cache_dir = Path.build_filename(Environment.get_user_cache_dir(),
                                      Config.PACKAGE);
    if (cache_dir != null && DejaDup.ensure_directory_exists(cache_dir))
      argv.append("--archive-dir=" + cache_dir);

    // Specify tempdir
    var tempdir = yield DejaDup.get_tempdir();
    if (DejaDup.ensure_directory_exists(tempdir))
      argv.append("--tempdir=%s".printf(tempdir));

    // Finally, actual duplicity command
    argv.prepend("duplicity");
    
    // Grab version of command line to show user
    string user_cmd = null;
    foreach(string a in argv) {
      if (a == null)
        break;
      if (user_cmd == null)
        user_cmd = a;
      else
        user_cmd = "%s %s".printf(user_cmd, Shell.quote(a));
    }

    // Add logging argument (after building user-visible command above, as we
    // don't want users to try to use --log-fd on console and get errors)
    if (as_root) {
      // Make log file
      logfile = File.new_tmp(Config.PACKAGE + "-XXXXXX", out logstream);
      argv.append("--log-file=%s".printf(logfile.get_path()));
    }
    else {
      // Open pipes to communicate with subprocess
      if (Posix.pipe(pipes) != 0)
        return false;

      argv.append("--log-fd=%d".printf(pipes[1]));
    }

    // Run as root if needed
    if (as_root &&
        Environment.find_program_in_path("pkexec") != null) {
      // Set environment variables for subprocess here because pkexec reserves
      // the right to strip them.
      StringBuilder args = new StringBuilder();
      foreach (string env in envp_in)
        args.append("%s\n".printf(env));

      IOStream iostream;
      scriptfile = File.new_tmp(Config.PACKAGE + "-XXXXXX", out iostream);
      yield iostream.get_output_stream().write_all_async(args.data, Priority.DEFAULT, null, null);

      argv.prepend(scriptfile.get_path());
      argv.prepend(Path.build_filename(Config.PKG_LIBEXEC_DIR, "duplicity"));
      argv.prepend("pkexec");
    }
    
    string[] real_argv = new string[argv.length()];
    i = 0;
    foreach(string a in argv)
      real_argv[i++] = a;
    
    // Kill any lockfile, since our cancel methods may leave them around.
    // We already are pretty sure we don't have other duplicities in our
    // archive directories, because we use our own and we ensure we only have
    // one deja-dup running at a time via DBus.
    Posix.system("/bin/rm -f " + Shell.quote(cache_dir) + "/*/lockfile.lock");

    Process.spawn_async_with_pipes(null, real_argv, real_envp,
                        SpawnFlags.SEARCH_PATH |
                        SpawnFlags.DO_NOT_REAP_CHILD |
                        SpawnFlags.LEAVE_DESCRIPTORS_OPEN |
                        SpawnFlags.STDOUT_TO_DEV_NULL |
                        SpawnFlags.STDERR_TO_DEV_NULL,
                        () => {
                          // Drop support for /dev/tty inside duplicity.
                          // See our PASSPHRASE handling for more info.
                          Posix.setsid();
                        }, out child_pid, null, null, null);
    
    debug("Running the following duplicity (%i) command: %s\n", (int)child_pid, user_cmd);
    
    watch_id = ChildWatch.add(child_pid, spawn_finished);
    
    if (pipes[1] != -1)
      Posix.close(pipes[1]);
    
    yield read_log();
    return true;
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

  public void pause()
  {
    if (is_started())
      stop_child();
  }

  public void resume()
  {
    if (is_started())
      cont_child();
  }
  
  uint watch_id;
  Pid child_pid;
  int[] pipes;
  DataInputStream reader;
  File logfile;
  IOStream logstream;
  File scriptfile;
  bool process_done;
  int status;
  bool processed_a_message;
  construct {
    pipes = new int[2];
    pipes[0] = pipes[1] = -1;
  }
  
  ~DuplicityInstance()
  {
    if (watch_id != 0)
      Source.remove(watch_id);
    
    if (is_started()) {
      debug("duplicity (%i) process killed\n", (int)child_pid);
      kill_child();
    }
    
    try {
      if (scriptfile != null)
        scriptfile.delete(null);
    }
    catch (Error e) {warning("%s\n", e.message);}
  }
  
  void kill_child() {
    Posix.kill((Posix.pid_t)child_pid, Posix.SIGKILL);
  }

  void stop_child() {
    Posix.kill((Posix.pid_t)child_pid, Posix.SIGSTOP);
  }

  void cont_child() {
    Posix.kill((Posix.pid_t)child_pid, Posix.SIGCONT);
  }
  
  async void read_log_lines()
  {
    /*
     * Process data from stream that is returned by read_log
     *
     * As reader returns lines that are outputed by duplicity, read_log_lines makes sure
     * that data is processed at right speed and passes that data along the chain of functions. 
     */
    List<string> stanza = new List<string>();
    while (reader != null) {
      try {
        var line = yield reader.read_line_async(Priority.DEFAULT, null, null);
        if (line == null) { // EOF
          if (process_done) {
            send_done_for_status();
            break;
          }
          else {
            // We're reading faster than duplicity can provide.  Wait a bit
            // before trying again.
            Timeout.add_seconds(1, () => {read_log_lines.begin(); return false;});
            return; // skip cleanup at bottom of this function
          }
        }
        if (line != "") {
          if (verbose)
            print("DUPLICITY: %s\n", line);
          stanza.append(line);
        }
        else if (stanza != null) {
          if (verbose)
            print("\n"); // breather
          
          process_stanza(stanza);
          stanza = new List<string>();
        }
      }
      catch (Error err) {
        warning("%s\n", err.message);
        break;
      }
    }

    reader = null;
    if (logfile != null) {
      try {
        logfile.delete(null);
      }
      catch (Error e2) {warning("%s\n", e2.message);}
    }
    
    unref();
  }

  async void read_log()
  {
   /*
    * Asynchronous reading of duplicity's log via stream
    *
    * Stream initiated either from log file or pipe
    */
    InputStream stream;

    if (logstream != null)
      stream = logstream.get_input_stream();
    else
      stream = new UnixInputStream(pipes[0], true);

    reader = new DataInputStream(stream);

    // This loop goes on while rest of class is doing its work.  We ref
    // it to make sure that the rest of the class doesn't drop from under us.
    ref();
    yield read_log_lines();
  }
  
  // If start is < 0, starts at word.length - 1.
  static int num_suffix(string word, char ch, long start = -1)
  {
    int rv = 0;
    
    if (start < 0)
      start = (long)word.length - 1;
    
    for (long i = start; i >= 0; --i, ++rv)
      if (word[i] != ch)
        break;
    
    return rv;
  }
  
  static string validated_string(string s)
  {
    var rv = new StringBuilder();
    weak string p = s;
    
    while (p[0] != 0) {
      unichar ch = p.get_char_validated();
      if (ch == (unichar)(-1) || ch == (unichar)(-2)) {
        rv.append("�"); // the 'replacement character' in unicode
        p = (string)((char*)p + 1);
      }
      else {
        rv.append_unichar(ch);
        p = p.next_char();
      }
    }
    
    return rv.str;
  }
  
  static string compress_string(string s_in)
  {
    var rv = new StringBuilder.sized(s_in.length);
    weak char[] s = (char[])s_in;
    
    int i = 0;
    while (s[i] != 0) {
      if (s[i] == '\\' && s[i+1] != 0) {
        bool bare_escape = false;
        
        // http://docs.python.org/reference/lexical_analysis.html
        switch (s[i+1]) {
        case 'b': rv.append_c('\b'); i += 2; break; // backspace
        case 'f': rv.append_c('\f'); i += 2; break; // form feed
        case 't': rv.append_c('\t'); i += 2; break; // tab
        case 'n': rv.append_c('\n'); i += 2; break; // line feed
        case 'r': rv.append_c('\r'); i += 2; break; // carriage return
        case 'v': rv.append_c('\xb'); i += 2; break; // vertical tab
        case 'a': rv.append_c('\x7'); i += 2; break; // bell
        case 'U': // start of a hex number
          var val = DejaDup.strtoull(((string)s).substring(i+2, 8), null, 16);
          rv.append_unichar((unichar)val);
          i += 10;
          break;
        case 'u': // start of a hex number
          var val = DejaDup.strtoull(((string)s).substring(i+2, 4), null, 16);
          rv.append_unichar((unichar)val);
          i += 6;
          break;
        case 'x': // start of a hex number
          var val = DejaDup.strtoull(((string)s).substring(i+2, 2), null, 16);
          rv.append_unichar((unichar)val);
          i += 4;
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
            var val = DejaDup.strtoull((string)tmpstr, null, 8);
            rv.append_unichar((unichar)val);
            i += 5;
          }
          else
            bare_escape = true;
          break;
        default:
          bare_escape = true; break;
        }
        if (bare_escape) {
          rv.append_c(s[i+1]); i+=2;
        }
      }
      else
        rv.append_c(s[i++]);
    }
    
    return rv.str;
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
        word = word.chomp();
      
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
            num_suffix(word, '\\', (long)word.length - 2) % 2 == 0)
          in_group = false;
        // Else...  If it ends with just a backslash, the backslash was
        // supposed to be for the space.  So just drop it.
        else if (num_suffix(word, '\\') % 2 == 1)
          // Chop off last backslash.
          word = word.substring(0, word.length - 2);
        
        // get rid of any other escaping backslashes and translate octals
        word = compress_string(word);
        
        // Now join to rest of group.
        if (group_word == "")
          group_word = word;
        else
          group_word += " " + word;
        
        if (!in_group) {
          // add to list, but drop single quotes
          splitlist.append(group_word.substring(1, group_word.length - 2));
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
    /*
     * Split the line/stanza that was echoed by stream and pass it forward in a 
     * more structured way via a signal.
     */
    string[] control_line;
    split_line(stanza.data, out control_line);
    
    var data = grab_stanza_data(stanza);
    
    var text = grab_stanza_text(stanza);
    
    processed_a_message = true;
    message(control_line, data, text);
  }
  
  List<string> grab_stanza_data(List<string> stanza)
  {
    /*
     * Return only data from stanza that was returned by stream
     */
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
        text = "%s%s\n".printf(text, validated_string(split[1]));
      }
    }
    return text.chomp();
  }
  
  void spawn_finished(Pid pid, int status)
  {
    this.status = status;
    
    if (Process.if_exited(status)) {
      var exitval = Process.exit_status(status);
      debug("duplicity (%i) exited with value %i\n", (int)pid, exitval);
    }
    else {
      debug("duplicity (%i) process killed\n", (int)pid);
    }
    
    watch_id = 0;
    Process.close_pid(pid);
    
    process_done = true;
    if (reader == null)
      send_done_for_status();
  }
  
  void send_done_for_status()
  {
    bool success = Process.if_exited(status) && Process.exit_status(status) == 0;
    bool cancelled = !Process.if_exited(status);
    
    if (Process.if_exited(status) && !processed_a_message &&
        (Process.exit_status(status) == 126 || // pkexec returns 126 on cancel
         Process.exit_status(status) == 127))  // and 127 on bad password
      cancelled = true;

    if (Process.if_exited(status))
      exited(Process.exit_status(status));

    child_pid = (Pid)0;
    done(success, cancelled);
  }
}

