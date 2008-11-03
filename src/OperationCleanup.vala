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

public class OperationCleanup : Operation
{
  construct
  {
    dup.progress_label = _("Cleaning up...");
  }
  
  protected override string[]? make_argv() throws Error
  {
    var target = backend.get_location();
    
    if (target == null)
      return null;
    
    string[] argv = new string[5];
    int i = 0;
    argv[i++] = "duplicity";
    argv[i++] = "cleanup";
    argv[i++] = "--force";
    argv[i++] = target;
    argv[i++] = null;
    return argv;
  }
}

