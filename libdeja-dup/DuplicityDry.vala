/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
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

/* This class runs duplicity, but in --dry-run mode.  It's really only for one
   purpose: finding out how many bytes need to be processed by duplicity to
   back up.  We then use that information to present a progress bar during the
   real (wet) run. */

public class DuplicityDry : Duplicity
{
  public uint total_bytes {get; protected set; default = 0;}
  
  public DuplicityDry(Operation.Mode mode, Gtk.Window? win) {
    base(mode, win);
  }
  
  public override void start(List<string> argv, List<string>? envp) throws SpawnError
  {
    argv.append("--dry-run");
    base.start(argv, envp);
  }
  
  protected override void process_info(string[] firstline, List<string> stanza)
  {
    if (firstline.length > 1) {
      switch (firstline[1].to_int()) {
      case INFO_PROGRESS:
        if (firstline.length > 2) {
          total_bytes = firstline[2].to_int();
        }
        break;
      }
    }
    base.process_info(firstline, stanza);
  }
}

} // end namespace

