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

public class ResticPlugin : DejaDup.ToolPlugin
{
	bool has_been_setup = false;

	construct
	{
		name = "Restic";
	}

	public override string[] get_dependencies()
	{
		return Config.RESTIC_PACKAGES.split(",");
	}

	void do_initial_setup () throws Error
	{
		// version check?
	}

	public override DejaDup.ToolJob create_job () throws Error
	{
		if (!has_been_setup) {
			do_initial_setup();
			has_been_setup = true;
		}
		return new ResticJob();
	}
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type (typeof (Peas.Activatable),
									   typeof (ResticPlugin));
}
