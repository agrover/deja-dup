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

// we don't want to include external strings in our pot file
[CCode (cname = "g_dgettext", cheader_filename = "glib/gi18n-lib.h")]
public extern unowned string external_dgettext (string? domain, [FormatArg] string msgid);

namespace DejaDup {

public class ConfigLabelDescription : ConfigLabel
{
  public enum Kind {BACKUP, RESTORE}
  public Kind kind {get; construct;}

  public ConfigLabelDescription(Kind kind)
  {
    Object(kind: kind);
  }

  construct {
    watch_key(DejaDup.LAST_BACKUP_KEY);
    if (kind == Kind.BACKUP) {
      watch_key(DejaDup.PERIODIC_KEY);
      watch_key(DejaDup.PERIODIC_PERIOD_KEY);
    }
    notify["everything-installed"].connect((s, p) => {
      set_from_config.begin();
    });
  }

  protected override void fill_box()
  {
    base.fill_box();
    label.use_markup = true;
    label.wrap = true;
    label.max_width_chars = 60;
    // The only links we use is to enable the auto backup, so assume that's what's happening
    label.activate_link.connect(enable_auto_backup);
  }

  void set_from_config_restore()
  {
    var val = DejaDup.last_run_date(DejaDup.TimestampType.BACKUP);

    // This here encodes a lot of outside GUI information in this widget,
    // but it's a very special case thing.
    var time = TimeVal();
    var button_name = "<b>%s</b>".printf(_("Restore…"));
    if (val == "" || !time.from_iso8601(val))
      label.label = _("You may use the %s button to browse for existing backups.").printf(button_name);
    else {
      var file_manager = external_dgettext("nautilus", "Files");
      if (Environment.get_variable("XDG_CURRENT_DESKTOP") == "MATE")
        file_manager = external_dgettext("caja", "Caja");
      label.label = _("You can restore the entire backup with the %s button or use %s to either revert individual files or restore missing ones.").printf(button_name, file_manager);
    }
  }

  void set_from_config_backup()
  {
    var next = DejaDup.next_run_date();
    if (next == null) {
      var button_name = "<b>%s</b>".printf(_("Back Up Now…"));
      label.label = _("You should <a href=''>enable</a> automatic backups or use the %s button to start one now.").printf(button_name);
    }
    else {
      var period = settings.get_int(DejaDup.PERIODIC_PERIOD_KEY);
      string desc;
      if (period == 1)
        desc = _("A backup automatically starts every day.");
      else if (period == 7)
        desc = _("A backup automatically starts every week.");
      else
        desc = dngettext(Config.GETTEXT_PACKAGE,
                         "A backup automatically starts every %d day.",
                         "A backup automatically starts every %d days.", period).printf(period);
      label.label = desc;
    }
  }

  protected override async void set_from_config()
  {
    if (kind == Kind.RESTORE)
      set_from_config_restore();
    else
      set_from_config_backup();
  }

  bool enable_auto_backup()
  {
    var settings = DejaDup.get_settings();
    settings.set_boolean(DejaDup.PERIODIC_KEY, true);
    return true;
  }
}

}
