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

public class OperationCleanup : Operation
{
  public OperationCleanup(Gtk.Window? win) {
    toplevel = win;
    mode = Mode.CLEANUP;
  }
  
  protected override List<string>? make_argv() throws Error
  {
    var target = backend.get_location();
    
    if (target == null)
      return null;
    
    List<string> argv = new List<string>();
    argv.append("cleanup");
    argv.append("--force");
    argv.append(target);
    return argv;
  }
}

} // end namespace

