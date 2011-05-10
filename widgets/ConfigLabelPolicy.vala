/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2010 Michael Terry <mike@mterry.name>
    © 2011 Canonical Ltd

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

public class ConfigLabelPolicy : ConfigLabel
{
  public ConfigLabelPolicy()
  {
    Object(key: null);
  }

  construct {
    watch_key(BACKEND_KEY);
    watch_key(FILE_PATH_KEY, DejaDup.get_settings(FILE_ROOT));
    watch_key(DELETE_AFTER_KEY);
    
    var attrs = new Pango.AttrList();
    attrs.insert(Pango.attr_style_new(Pango.Style.ITALIC));
    label.set_attributes(attrs);
    label.wrap = true;
  }
  
  protected override async void set_from_config()
  {
    Backend backend = Backend.get_default();
    int delete_after = settings.get_int(DELETE_AFTER_KEY);
    
    bool infinite = backend.space_can_be_infinite();
    if (infinite) {
      // Don't bother showing anything because the policy is just the same
      // as the delete_after setting.  So the user can just look at that.
      label.label = "";
      return;
    }
    
    string policy;
    
    if (delete_after <= 0)
      delete_after = ConfigDelete.FOREVER;
    
    if (delete_after == ConfigDelete.WEEKLY)
      policy = _("Old backups will be kept for at least a week or until the backup location is low on space.");
    else if (delete_after == ConfigDelete.MONTHLY)
      policy = _("Old backups will be kept for at least a month or until the backup location is low on space.");
    else if (delete_after == ConfigDelete.BIMONTHLY)
      policy = _("Old backups will be kept for at least two months or until the backup location is low on space.");
    else if (delete_after == ConfigDelete.TRIMONTHLY)
      policy = _("Old backups will be kept for at least three months or until the backup location is low on space.");
    else if (delete_after == ConfigDelete.SEMIANNUALLY)
      policy = _("Old backups will be kept for at least six months or until the backup location is low on space.");
    else if (delete_after == ConfigDelete.ANNUALLY)
      policy = _("Old backups will be kept for at least a year or until the backup location is low on space.");
    else if (delete_after == ConfigDelete.FOREVER)
      policy = _("Old backups will be kept until the backup location is low on space.");
    else
      policy = ngettext("Old backups will be kept at least %d day or until the backup location is low on space.",
                        "Old backups will be kept at least %d days or until the backup location is low on space.",
                        delete_after).printf(delete_after);
    
    label.label = policy;
  }
}

}

