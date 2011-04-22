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
  public enum Kind {LAST, NEXT}
  public Kind kind {get; construct;}
  public bool empty {get; protected set; default = true;}

  public ConfigLabelBackupDate(Kind kind)
  {
    Object(kind: kind);
  }

  construct {
    watch_key(DejaDup.LAST_BACKUP_KEY);
    watch_key(DejaDup.LAST_RUN_KEY);
    if (kind == Kind.NEXT) {
      watch_key(DejaDup.PERIODIC_KEY);
      watch_key(DejaDup.PERIODIC_PERIOD_KEY);
    }
  }

  bool is_same_day(DateTime one, DateTime two)
  {
    int ny, nm, nd, dy, dm, dd;
    one.get_ymd(out ny, out nm, out nd);
    two.get_ymd(out dy, out dm, out dd);
    return (ny == dy && nm == dm && nd == dd);
  }

  string pretty_date_name(DateTime date)
  {
      var now = new DateTime.now_local();

      // Check for some really simple/common friendly names
      if (is_same_day(date, now))
        return _("Today");
      else if (is_same_day(date, now.add_days(-1)))
        return _("Yesterday");
      else if (is_same_day(date, now.add_days(1)))
        return _("Tomorrow");
      else
        return date.format("%x");
  }

  protected void set_from_config_last()
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
      label.label = pretty_date_name(new DateTime.from_timeval_local(time));
      empty = false;
    }
  }

  protected void set_from_config_next()
  {
    var next = DejaDup.next_run_date();
    if (next.valid()) {
      var nextd = new DateTime.local(next.get_year(),
                                     next.get_month(),
                                     next.get_day(),
                                     0, 0, 0.0);
      label.label = pretty_date_name(nextd);
      empty = false;
    }
    else {
      label.label = "";
      empty = true;
    }
  }

  protected override async void set_from_config()
  {
    if (kind == Kind.LAST)
      set_from_config_last();
    else
      set_from_config_next();
  }
}

}

