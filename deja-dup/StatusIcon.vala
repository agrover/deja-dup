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

public class StatusIcon : Object
{
  public signal void toggle_window();
  public signal void hide_all();
  public Gtk.Window? window {get; construct;}
  public DejaDup.Operation op {get; construct;}
  public bool automatic {get; construct; default = false;}

  string action;
  double progress;

  Gtk.Menu menu;
  Gtk.MenuItem toggle_item;
  Object iconobj;
  
  public StatusIcon(Gtk.Window? window, DejaDup.Operation op, bool automatic)
  {
    Object(window: window, op: op, automatic: automatic);
  }

  construct {
    ensure_menu();
    iconobj = hacks_status_icon_make_app_indicator(menu);
    
    if (window != null) {
      window.show.connect((w) => {
        toggle_item.label = _("Hide _Progress");
      });
      window.hide.connect((w) => {
        toggle_item.label = _("Show _Progress");
      });
    }
    
    if (iconobj == null) {
      var gtkicon = new Gtk.StatusIcon();
      gtkicon.set("icon-name", "deja-dup-applet",
                  "title", _("Déjà Dup")); // Only in GTK+ 2.18
      
      if (op.mode == DejaDup.Operation.Mode.BACKUP)
        gtkicon.popup_menu.connect(show_menu);

      gtkicon.activate.connect((s) => {
        toggle_window();
      });

      op.action_desc_changed.connect(set_action_desc);
      op.progress.connect(note_progress);
      
      iconobj = gtkicon;
    }
  }

  ~StatusIcon()
  {
    // FIXME: icon won't die, even with this call
    hacks_status_icon_close_app_indicator(iconobj);
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
    hacks_status_icon_set_tooltip_text((Gtk.StatusIcon)iconobj, tooltip);
  }

  void later()
  {
    hide_all();
    op.stop();
  }

  void skip()
  {
    hide_all();

    // Fake a run by setting today's timestamp as the 'last-run' gconf key
    try {
      DejaDup.update_last_run_timestamp();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }

    op.cancel();
  }
  
  Gtk.Menu ensure_menu()
  {
    if (menu != null)
      return menu;
    
    menu = new Gtk.Menu();

    Gtk.MenuItem item;

    if (window.visible)
      item = new Gtk.MenuItem.with_mnemonic(_("Hide _Progress"));
    else
      item = new Gtk.MenuItem.with_mnemonic(_("Show _Progress"));
    item.activate.connect((i) => {toggle_window();});
    menu.append(item);
    toggle_item = item;

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
    return menu;
  }
  
  void show_menu(Gtk.StatusIcon status_icon, uint button, uint activate_time)
  {
    menu.popup(null, null, status_icon.position_menu, button, activate_time);
  }
}

