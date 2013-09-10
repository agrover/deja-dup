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

public class ConfigURLPartBool : ConfigBool
{
  public delegate bool TestActive(string val);
  public ConfigURLPart.Part part {get; construct;}

  unowned TestActive _test_active;
  public unowned TestActive test_active {
    get {return _test_active;}
    set {
      _test_active = value;
      set_from_config.begin();
    }
  }

  public ConfigURLPartBool(ConfigURLPart.Part part, string key, string ns,
                           string label) {
    Object(key: key, ns: ns, part: part, label: label);
  }

  protected override async void set_from_config()
  {
    if (test_active != null) {
      var userval = ConfigURLPart.read_uri_part(settings, key, part);
      var prev = user_driven;
      user_driven = false;
      button.active = test_active(userval);
      user_driven = prev;
    }
  }

  protected override void handle_toggled()
  {
    toggled(this, user_driven);
  }
}

}

