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

public class DuplicityPlugin : DejaDup.ToolPlugin
{
  bool has_been_setup = false;

  construct
  {
    name = "Duplicity";
  }

  static const int REQUIRED_MAJOR = 0;
  static const int REQUIRED_MINOR = 6;
  static const int REQUIRED_MICRO = 14;
  void do_initial_setup () throws Error
  {
    string output;
    Process.spawn_command_line_sync("duplicity --version", out output, null, null);

    var tokens = output.split(" ", 2);
    if (tokens == null || tokens[0] == null || tokens[1] == null)
      throw new SpawnError.FAILED(_("Could not understand duplicity version."));

    // First token is 'duplicity' and is ignorable.  Second looks like '0.5.03'
    var version_string = tokens[1].strip();
    var ver_tokens = version_string.split(".");
    if (ver_tokens == null || ver_tokens[0] == null)
      throw new SpawnError.FAILED(_("Could not understand duplicity version ‘%s’.").printf(version_string));

    int major = 0;
    int minor = 0;
    int micro = 0;
    major = int.parse(ver_tokens[0]);
    // Don't error out if no minor or micro.  Duplicity might not have them?
    if (ver_tokens[1] != null) {
      minor = int.parse(ver_tokens[1]);
      if (ver_tokens[2] != null)
        micro = int.parse(ver_tokens[2]);
    }

    var meets = (major > REQUIRED_MAJOR) ||
                (major == REQUIRED_MAJOR && minor > REQUIRED_MINOR) ||
                (major == REQUIRED_MAJOR && minor == REQUIRED_MINOR && micro >= REQUIRED_MICRO);
    if (!meets)
      throw new SpawnError.FAILED(_("Déjà Dup Backup Tool requires at least version %d.%d.%.2d of duplicity, but only found version %d.%d.%.2d").printf(REQUIRED_MAJOR, REQUIRED_MINOR, REQUIRED_MICRO, major, minor, micro));
  }

  public override DejaDup.ToolJob create_job () throws Error
  {
    if (!has_been_setup) {
      do_initial_setup();
      has_been_setup = true;
    }
    return new DuplicityJob();
  }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
  var objmodule = module as Peas.ObjectModule;
  objmodule.register_extension_type (typeof (Peas.Activatable),
                                     typeof (DuplicityPlugin));
}

