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

/**
 * There are three modes for 'shell' integration:
 * 1) GNOME Shell
 * 2) Unity
 * 3) Legacy
 * 
 * GNOME Shell:
 * No status icon at all.
 * Actions on persistent notifications.
 * Detected by 'persistent' capability of notification server.
 * Automatic-start and success notifications.
 * 
 * Unity:
 * Register as a launcher entry.
 * Always shows progress.
 * Success notification.
 * Detected by presence of Unity (usually on Ubuntu).
 * 
 * Legacy:
 * Standard GTK+ status icon.
 * Success notification.
 */

public abstract class StatusIcon : Object
{
  public static StatusIcon create(Gtk.Window window, DejaDup.Operation op, bool automatic)
  {
    // Check unity first, since it is most direct.  Then try to guess shell
    // based on notification capabilities.  Then just see whether we were built
    // for indicators or not.
    StatusIcon instance = null;
    switch (DejaDup.get_shell()) {
#if HAVE_UNITY
    case DejaDup.ShellEnv.UNITY:
      instance = new UnityStatusIcon(window, op, automatic);
      break;
#endif

    case DejaDup.ShellEnv.GNOME:
      instance = new ShellStatusIcon(window, op, automatic);
      break;

    default:
      instance = new LegacyStatusIcon(window, op, automatic);
      break;
    }
    return instance;
  }

  public enum CloseAction {
    HIDE,
    MINIMIZE,
  }

  public signal void show_window();
  public signal void hide_all();
  public Gtk.Window? window {get; construct;}
  public DejaDup.Operation op {get; construct;}
  public bool automatic {get; construct; default = false;}

  public bool show_automatic_progress {get; protected set; default = false;}

  protected string action;
  protected double progress;

  protected string later_label;
  protected string skip_label;

  protected Notify.Notification note;

  construct {
    later_label = _("_Resume Later");
    skip_label = _("_Skip Backup");

    op.action_desc_changed.connect(set_action_desc);
    op.progress.connect(note_progress);
  }

  void set_action_desc(DejaDup.Operation op, string action)
  {
    this.action = action;
    update_progress();
  }

  void note_progress(DejaDup.Operation op, double progress)
  {
    this.progress = progress;
    update_progress();
  }

  public virtual void done(bool success, bool cancelled, string? detail)
  {
    if (note != null) {
      try {
        // We're done with this backup, no need to still talk about it
        note.close();
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    }

    if (success && !cancelled && op.mode == DejaDup.ToolJob.Mode.BACKUP) {
      string msg = _("Backup completed");

      string more = null;
      if (detail != null) {
        msg = _("Backup finished");
        more = _("Not all files were successfully backed up.  See dialog for more details.");
      }

      Notify.init(_("Backup"));
      note = new Notify.Notification(msg, more, "deja-dup");
      try {
        note.show();
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    }
  }

  protected virtual void update_progress() {}

  protected void later()
  {
    hide_all();
    op.stop();
  }

  protected void skip()
  {
    hide_all();

    // Fake a run by setting today's timestamp as the 'last-run' setting
    DejaDup.update_last_run_timestamp(DejaDup.TimestampType.NONE);

    op.cancel();
  }
}

#if HAVE_UNITY
class UnityStatusIcon : StatusIcon
{
  public UnityStatusIcon(Gtk.Window window, DejaDup.Operation op, bool automatic)
  {
    Object(window: window, op: op, automatic: automatic);
  }

  Unity.LauncherEntry entry;
  construct {
    entry = Unity.LauncherEntry.get_for_desktop_id("deja-dup.desktop");
    show_automatic_progress = true;
    if (entry != null) {
      entry.quicklist = ensure_menu();
      update_progress();
    }
  }

  ~UnityStatusIcon()
  {
    if (entry != null) {
      entry.progress_visible = false;
      entry.quicklist = null;
    }
  }

  protected override void update_progress()
  {
    if (entry != null) {
      entry.progress = this.progress;
      entry.progress_visible = true;
    }
  }

  Dbusmenu.Menuitem? ensure_menu()
  {
    Dbusmenu.Menuitem menu = null;

    if (op.mode == DejaDup.ToolJob.Mode.BACKUP) {
      menu = new Dbusmenu.Menuitem();

      var item = new Dbusmenu.Menuitem();
      item.property_set(Dbusmenu.MENUITEM_PROP_LABEL, later_label);
      item.item_activated.connect((i) => {later();});
      menu.child_append(item);

      if (automatic) {
        item = new Dbusmenu.Menuitem();
        item.property_set(Dbusmenu.MENUITEM_PROP_LABEL, skip_label);
        item.item_activated.connect((i) => {skip();});
        menu.child_append(item);
      }
    }

    return menu;
  }
}
#endif

class ShellStatusIcon : StatusIcon
{
  public ShellStatusIcon(Gtk.Window window, DejaDup.Operation op, bool automatic)
  {
    Object(window: window, op: op, automatic: automatic);
  }

  construct {
    if (automatic && op.mode == DejaDup.ToolJob.Mode.BACKUP) {
      Notify.init(_("Backup"));
      note = new Notify.Notification(_("Starting scheduled backup"), null,
                                     "deja-dup");
      note.add_action("show-details", _("Show Progress"), () => {show_window();});
      note.add_action("later", later_label.replace("_", ""), () => {later();});
      note.add_action("skip", skip_label.replace("_", ""), () => {skip();});
      try {
        note.show();
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
    }
  }
}

class LegacyStatusIcon : StatusIcon
{
  public LegacyStatusIcon(Gtk.Window window, DejaDup.Operation op, bool automatic)
  {
    Object(window: window, op: op, automatic: automatic);
  }

  Gtk.Menu menu;
  Gtk.StatusIcon icon;
  construct {
    icon = new Gtk.StatusIcon();
    icon.set("icon-name", "deja-dup-symbolic",
             "title", Environment.get_application_name());

    ensure_menu();
    icon.popup_menu.connect(show_menu);
    icon.activate.connect((s) => {show_menu(s, 0, Gtk.get_current_event_time());});
  }

  protected override void update_progress()
  {
    var tooltip = "";
    if (this.action != null)
      tooltip = this.action;
    if (this.progress > 0)
      tooltip = tooltip + "\n" + _("%.1f%% complete").printf(this.progress * 100);
    icon.set_tooltip_text(tooltip);
  }

  void show_menu(Gtk.StatusIcon status_icon, uint button, uint activate_time)
  {
    menu.popup(null, null, status_icon.position_menu, button, activate_time);
  }

  void ensure_menu()
  {
    menu = new Gtk.Menu();

    var progressitem = new Gtk.MenuItem.with_mnemonic(_("Show _Progress"));
    progressitem.activate.connect((i) => {show_window();});
    menu.append(progressitem);

    if (op.mode == DejaDup.ToolJob.Mode.BACKUP) {
      Gtk.MenuItem item;

      menu.append(new Gtk.SeparatorMenuItem());

      item = new Gtk.MenuItem.with_mnemonic(later_label);
      item.activate.connect((i) => {later();});
      menu.append(item);

      if (automatic) {
        item = new Gtk.MenuItem.with_mnemonic(skip_label);
        item.activate.connect((i) => {skip();});
        menu.append(item);
      }
    }

    update_progress();

    menu.show_all();
  }
}

