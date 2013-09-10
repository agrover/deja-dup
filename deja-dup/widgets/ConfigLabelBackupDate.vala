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

public class ConfigLabelBackupDate : ConfigLabel
{
  public enum Kind {LAST, NEXT}
  public Kind kind {get; construct;}

  public ConfigLabelBackupDate(Kind kind)
  {
    Object(kind: kind);
  }

  construct {
    watch_key(DejaDup.LAST_BACKUP_KEY);
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

      if (kind == Kind.NEXT && now.compare(date) > 0) {
        // never allow next date to be in the past
        date = now;
      }

      // Check for some really simple/common friendly names
      if (is_same_day(date, now))
        return _("Today");
      else if (is_same_day(date, now.add_days(-1)))
        return _("Yesterday");
      else if (is_same_day(date, now.add_days(1)))
        return _("Tomorrow");
      else if (now.compare(date) < 0) {
        // date is in future
        now = new DateTime.local(now.get_year(),
                                 now.get_month(),
                                 now.get_day_of_month(),
                                 0, 0, 0.0);
        var diff = (int)(date.difference(now) / TimeSpan.DAY);
        return dngettext(Config.GETTEXT_PACKAGE, "%d day from now",
                         "%d days from now", diff).printf(diff);
      }
      else {
        // date is in past
        now = new DateTime.local(now.get_year(),
                                 now.get_month(),
                                 now.get_day_of_month(),
                                 0, 0, 0.0);
        var diff = (int)(now.difference(date) / TimeSpan.DAY + 1);
        return dngettext(Config.GETTEXT_PACKAGE, "%d day ago",
                         "%d days ago", diff).printf(diff);
      }
  }

  protected void set_from_config_last()
  {
    var val = DejaDup.last_run_date(DejaDup.TimestampType.BACKUP);

    var time = TimeVal();
    if (val == "" || !time.from_iso8601(val)) {
      // Translators: This is used in phrases like "Most recent backup: None"
      label.label = _("None");
    }
    else {
      label.label = pretty_date_name(new DateTime.from_timeval_local(time));
    }
  }

  protected void set_from_config_next()
  {
    var next = DejaDup.next_run_date();
    if (next != null) {
      label.label = pretty_date_name(next);
    }
    else {
      label.label = _("None");
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

