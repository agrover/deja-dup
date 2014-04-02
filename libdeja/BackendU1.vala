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

public class BackendU1 : Backend
{
  public override Backend clone() {
    return new BackendU1();
  }

  public override bool is_native() {
    return false;
  }

  public override Icon? get_icon() {
    return new ThemedIcon.from_names({"ubuntuone", "ubuntuone-installer", "deja-dup-cloud"});
  }

  public override string get_location(ref bool as_root)
  {
    return "";
  }

  public override string get_location_pretty()
  {
    return _("Ubuntu One");
  }

  public override async void get_envp() throws Error
  {
    throw new BackupError.BAD_CONFIG(_("Ubuntu One has shut down.  Please choose another storage location."));
  }
}

} // end namespace

