/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2010 Michael Terry <mike@mterry.name>

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

  TestActive _test_active;
  public TestActive test_active {
    get {return _test_active;}
    set {
      _test_active = value;
      set_from_config();
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
      button.disconnect(toggle_id);
      button.active = test_active(userval);
      toggled(this, false);
      toggle_id = button.toggled.connect(handle_toggled);
    }
  }

  protected override void handle_toggled()
  {
    toggled(this, true);
  }
}

}

