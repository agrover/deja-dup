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
 * There are four modes for 'shell' integration:
 * 1) GNOME Shell
 * 2) Unity
 * 3) Indicator
 * 4) Legacy
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
 * Indicator:
 * Register as an application indicator, which falls back to standard GTK+ status icon.
 * Success notification.
 * Detected by presence of application indicator host (usually on Ubuntu).
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
    case DejaDup.ShellEnv.UNITY:
      instance = new UnityStatusIcon(window, op, automatic);
      break;

    case DejaDup.ShellEnv.GNOME:
      instance = new ShellStatusIcon(window, op, automatic);
      break;

    default:
      instance = new IndicatorStatusIcon(window, op, automatic);
      if (!instance.is_valid)
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

  public CloseAction close_action {get; protected set; default = CloseAction.HIDE;}
  public bool show_automatic_progress {get; protected set; default = false;}

  protected bool is_valid = true;
  protected string action;
  protected double progress;

  protected string later_label;
  protected string skip_label;

  protected Gtk.Menu menu;
  protected Notify.Notification note;

  construct {
    if (DejaDup.DuplicityInfo.get_default().can_resume)
      later_label = _("_Resume Later");
    else if (automatic)
      later_label = _("_Delay Backup");
    else
      later_label = _("_Cancel Backup");
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

  public virtual void done(bool success, bool cancelled)
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

    if (success && !cancelled && op.mode == DejaDup.Operation.Mode.BACKUP) {
      Notify.init(_("Backup"));
      note = new Notify.Notification(_("Backup completed"), null,
                                     "deja-dup");
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

  protected Gtk.Menu ensure_menu(bool show_self = true)
  {
    if (menu != null)
      return menu;

    menu = new Gtk.Menu();

    if (show_self) {
      Gtk.ImageMenuItem imageitem;
      imageitem = new Gtk.ImageMenuItem.with_mnemonic(_("Déjà Du_p"));
      imageitem.image = new Gtk.Image.from_icon_name("deja-dup-symbolic", Gtk.IconSize.MENU);
      imageitem.always_show_image = true;
      imageitem.activate.connect((i) => {show_window();});
      menu.append(imageitem);
    }

    if (op.mode == DejaDup.Operation.Mode.BACKUP) {
      Gtk.MenuItem item;

      if (show_self)
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
    return menu;
  }
}

class UnityStatusIcon : StatusIcon
{
  public UnityStatusIcon(Gtk.Window window, DejaDup.Operation op, bool automatic)
  {
    Object(window: window, op: op, automatic: automatic);
  }

  Object entry;
  construct {
    entry = hacks_unity_get_entry();
    is_valid = entry != null;
    close_action = CloseAction.MINIMIZE;
    show_automatic_progress = true;
    if (is_valid)
      hacks_unity_entry_set_menu(entry, ensure_menu(false));
  }

  ~UnityStatusIcon()
  {
    if (entry != null) {
      hacks_unity_entry_show_progress(entry, false);
      hacks_unity_entry_set_menu(entry, null);
    }
  }

  protected override void update_progress()
  {
    hacks_unity_entry_set_progress(entry, this.progress);
    hacks_unity_entry_show_progress(entry, true);
  }
}

class IndicatorStatusIcon : StatusIcon
{
  public IndicatorStatusIcon(Gtk.Window window, DejaDup.Operation op, bool automatic)
  {
    Object(window: window, op: op, automatic: automatic);
  }

  Object indicator;
  construct {
    indicator = hacks_status_icon_make_app_indicator(ensure_menu());
    is_valid = indicator != null;
  }

  ~IndicatorStatusIcon()
  {
    // FIXME: icon won't die, even with this call
    if (indicator != null)
      hacks_status_icon_close_app_indicator(indicator);
  }
}

class ShellStatusIcon : StatusIcon
{
  public ShellStatusIcon(Gtk.Window window, DejaDup.Operation op, bool automatic)
  {
    Object(window: window, op: op, automatic: automatic);
  }

  bool persistence = false;
  bool actions = false;
  construct {
    unowned List<string> caps = Notify.get_server_caps();
    foreach (string cap in caps) {
      if (cap == "persistence")
        persistence = true;
      else if (cap == "actions")
        actions = true;
    }

    is_valid = persistence && actions;

    if (is_valid && automatic && op.mode == DejaDup.Operation.Mode.BACKUP) {
      Notify.init(_("Backup"));
      note = new Notify.Notification(_("Starting scheduled backup"), null,
                                     "deja-dup");
      note.add_action("later", later_label.replace("_", ""), () => {later();});
      note.add_action("skip", skip_label.replace("_", ""), () => {skip();});
      try {
        note.show();
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }

      // Since we aren't using a status icon, no UI at all for this run, so no
      // need to calculate progress.
      op.use_progress = false;
    }
  }
}

class LegacyStatusIcon : StatusIcon
{
  public LegacyStatusIcon(Gtk.Window window, DejaDup.Operation op, bool automatic)
  {
    Object(window: window, op: op, automatic: automatic);
  }

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
}

