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

class AsyncCommand : Object
{
  public signal void done(bool success);
  public string[] argv {get; construct;}

  public AsyncCommand(string[] argv)
  {
    Object(argv: argv);
  }

  Pid pid = 0;
  uint watch = 0;
  MainLoop loop;
  construct {
    loop = new MainLoop(null, false);
  }

  ~AsyncCommand() {
    if (watch > 0)
      Source.remove(watch);
    if (pid > 0)
      handle_done(pid, 1); // fake error if we're still waiting
  }

  public void run()
  {
    try {
      if (!Process.spawn_async(null, argv, null,
                              SpawnFlags.STDOUT_TO_DEV_NULL |
                              SpawnFlags.STDERR_TO_DEV_NULL |
                              SpawnFlags.DO_NOT_REAP_CHILD |
                              SpawnFlags.SEARCH_PATH,
                              null, out pid))
        done(false);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      done(false);
    }

    watch = ChildWatch.add(pid, handle_done);
  }

  void handle_done(Pid pid, int sig)
  {
    done(sig == 0);
    Process.close_pid(pid);
    this.pid = 0;
  }
}

} // end namespace

