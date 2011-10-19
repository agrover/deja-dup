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

public class ConfigLabelList : ConfigLabel
{
  public ConfigLabelList(string key, string ns="")
  {
    Object(key: key, ns: ns);
  }

  construct {
    label.ellipsize = Pango.EllipsizeMode.END;
  }

  protected override async void set_from_config()
  {
    string val = null;
    var slist_val = settings.get_value(key);
    string*[] slist = slist_val.get_strv();

    var list = DejaDup.parse_dir_list(slist);

    foreach (File f in list) {
      string s = yield DejaDup.get_nickname(f);

      /* Make sure that any leading periods aren't treated as "breaking" by
         pango and thus screwing up our wrapping layout.
         (See https://launchpad.net/bugs/850430)
         Solution here is to use a character that *looks* like a period
         (U+2024 ONE DOT LEADER) and follow it with a non-breaking invisible
         character (U+2060 WORD JOINER).  A huge hack.  But I don't know how
         to tell Pango to treat periods as non-breaking...
       */
      if (s.length > 1 && s.has_prefix("."))
        s = s.splice(0, 1, "․\xE2\x81\xA0");

      if (val != null)
        val += ", %s".printf(s);
      else
        val = s;
    }

    label.label = val == null ? "" : val;
  }
}

}

