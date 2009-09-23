/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2009 Michael Terry <mike@mterry.name>

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

public class StatusIcon : Gtk.StatusIcon
{
  public signal void activated(uint time);
  public DejaDup.Operation op {get; construct;}
  public bool automatic {get; construct; default = false;}

  string action;
  double progress;
  public StatusIcon(DejaDup.Operation op, bool automatic)
  {
    this.op = op;
    this.automatic = automatic;
  }

  construct {
    icon_name = Config.PACKAGE;
    set("title", _("Déjà Dup")); // Only in GTK+ 2.18

    if (op.mode == DejaDup.Operation.Mode.BACKUP)
      popup_menu.connect(show_menu);

    activate.connect((s) => {
      activated(0);
    });

    op.action_desc_changed.connect(set_action_desc);
    op.progress.connect(note_progress);
  }

  void set_action_desc(DejaDup.Operation op, string action)
  {
    this.action = action;
    update_tooltip();
  }

  void note_progress(DejaDup.Operation op, double progress)
  {
    this.progress = progress;
    update_tooltip();
  }

  void update_tooltip()
  {
    var tooltip = "";
    if (this.action != null)
      tooltip = this.action;
    if (this.progress > 0)
      tooltip = tooltip + "\n" + _("%.1f%% complete").printf(this.progress * 100);
    hacks_status_icon_set_tooltip_text(this, tooltip);
  }

  void later()
  {
    op.stop();
  }

  void skip()
  {
    // Fake a run by setting today's timestamp as the 'last-run' gconf key
    try {
      DejaDup.update_last_run_timestamp();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }

    op.cancel();
  }

  void show_menu(Gtk.StatusIcon status_icon, uint button, uint activate_time)
  {
    var menu = new Gtk.Menu();

    Gtk.MenuItem item;

    if (DejaDup.DuplicityInfo.get_default().can_resume)
      item = new Gtk.MenuItem.with_mnemonic(_("_Resume Later"));
    else
      item = new Gtk.MenuItem.with_mnemonic(_("_Delay Backup"));
    item.activate.connect((i) => {later();});
    menu.append(item);

    if (automatic) {
      item = new Gtk.MenuItem.with_mnemonic(_("_Skip Backup"));
      item.activate.connect((i) => {skip();});
      menu.append(item);
    }

    menu.show_all();
    menu.popup(null, null, position_menu, button, activate_time);
  }
}

