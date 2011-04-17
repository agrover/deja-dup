/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2011 Michael Terry <mike@mterry.name>

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

public class ConfigLabelBackupDate : ConfigLabel
{
  public bool empty {get; protected set; default = true;}

  public ConfigLabelBackupDate()
  {
    Object();
  }

  construct {
    watch_key(DejaDup.LAST_BACKUP_KEY);
    watch_key(DejaDup.LAST_RUN_KEY);
  }

  protected override async void set_from_config()
  {
    var val = settings.get_string(DejaDup.LAST_BACKUP_KEY);
    if (val == "")
      val = settings.get_string(DejaDup.LAST_RUN_KEY);

    var time = TimeVal();
    if (val == "" || !time.from_iso8601(val)) {
      label.label = "";
      empty = true;
    }
    else {
      var now = new DateTime.now_local();
      var date = new DateTime.from_timeval_local(time);

      // Check for some really simple/common friendly names
      int ny, nm, nd, dy, dm, dd;
      now.get_ymd(out ny, out nm, out nd);
      date.get_ymd(out dy, out dm, out dd);
      if (ny == dy && nm == dm && nd == dd)
        label.label = _("Today");
      else if (ny == dy && nm == dm && nd - 1 == dd)
        label.label = _("Yesterday");
      else
        label.label = date.format("%x");

      empty = false;
    }
  }
}

}

