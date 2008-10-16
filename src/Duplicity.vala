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

[CCode (cheader_filename = "sys/wait.h")]
public class Duplicity : Object
{
  public signal void done(bool success);
  
  public string? progress_label {get; set; default = null;}
  
  public void start(string[] argv, string[]? envp) throws SpawnError
  {
    if (progress_label != null && progress == null) {
      progress = new Gtk.Dialog.with_buttons("", toplevel,
                                             Gtk.DialogFlags.MODAL |
                                             Gtk.DialogFlags.DESTROY_WITH_PARENT |
                                             Gtk.DialogFlags.NO_SEPARATOR,
                                             Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL);
      
      var label = new Gtk.Label(progress_label);
      label.set("xalign", 0.0f);
      progress.vbox.add(label);
      
      progress_bar = new Gtk.ProgressBar();
      progress.vbox.add(progress_bar);
      
      progress.response += handle_response;
    }
    
    var env_len = envp == null ? 0 : envp.length;
    string[] real_envp = new string[env_len + 1];
    int i = 0;
    for (; i < env_len; ++i)
      real_envp[i] = envp[i];
    real_envp[i] = null;
    
    string cmd = null;
    foreach(string a in argv)
      if (cmd == null)
        cmd = a;
      else if (a != null)
        cmd = "%s %s".printf(cmd, a);
    debug("Running the following duplicity command: %s", cmd);
    
    int stderr_fd;
    Process.spawn_async_with_pipes(null, argv, real_envp,
                        SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                        null, out child_pid, null, null, out stderr_fd);
    
    stderr = new IOChannel.unix_new(stderr_fd);
    
    this.timeout_id = Timeout.add(200, pulse);
    this.progress_bar.set_fraction(0); // Reset progress bar if this is second time we run this
    
    this.progress.show_all();
    
    ChildWatch.add(child_pid, spawn_finished);
  }
  
  uint timeout_id;
  Gtk.Dialog progress;
  Gtk.ProgressBar progress_bar;
  Pid child_pid;
  IOChannel stderr;
  construct {
    timeout_id = 0;
    stderr = null;
  }
  
  bool pulse()
  {
    progress_bar.pulse();
    return true;
  }
  
  void spawn_finished(Pid pid, int status)
  {
    progress.hide();
    progress = null;
    
    if (timeout_id != 0)
      Source.remove(timeout_id);
    
    bool success = Process.if_exited(status) && Process.exit_status(status) == 0;
    
    if (stderr != null) {
      if (Process.if_exited(status)) {
        var exitval = Process.exit_status(status);
        debug("duplicity exited with value %i", exitval);
        
        if (exitval != 0) {
          string errstr = null;
          try {
            stderr.read_to_end(out errstr, null);
            errstr.strip();
          } catch (Error e) {
            printerr("%s\n", e.message);
          }
          
          if (errstr != null) {
            var dlg = new Gtk.MessageDialog (toplevel, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, _("Error occurred"));
            dlg.format_secondary_text("%s".printf(errstr));
            dlg.run();
            dlg.destroy();
          }
        }
      }
      
      try {
        stderr.shutdown(false);
      } catch (Error e) {
        printerr("%s\n", e.message);
      }
      stderr = null;
    }
    
    Process.close_pid(pid);
    
    done(success);
  }
  
  void handle_response(Gtk.Dialog dlg, int response)
  {
    if (response == Gtk.ResponseType.CANCEL) {
      // FIXME: No way in vala to kill a process(?), so we do a kill call... Gross
      var cmd = "kill %i".printf((int)child_pid);
      try {
        Process.spawn_command_line_async(cmd);
      }
      catch (Error e) {
        printerr("%s\n", e.message);
      }
    }
  }
}

