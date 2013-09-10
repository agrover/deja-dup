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

class PythonChecker : Checker
{
  static HashTable<string, PythonChecker> modules;

  // returned objects guaranteed to never die
  public static PythonChecker get_checker(string module)
  {
    PythonChecker checker = null;

    if (modules == null)
      modules = new HashTable<string, PythonChecker>(str_hash, str_equal);
    else
      checker = modules.lookup(module);

    if (checker == null) {
      checker = new PythonChecker(module);
      modules.insert(module, checker);
    }

    return checker;
  }

  public string module {get; construct;}

  protected PythonChecker(string module)
  {
    Object(module: module);
  }

  AsyncCommand cmd;
  construct {
    string import = "import %s".printf(module);
    string[] argv = {"python", "-c", import};
    cmd = new AsyncCommand(argv);
    cmd.done.connect((s) => {
      available = s;
      complete = true;
    });
    cmd.run();
  }
}

} // end namespace

