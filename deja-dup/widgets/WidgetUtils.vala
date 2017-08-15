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

public void show_uri(Gtk.Window? parent, string link)
{
  try {
    Gtk.show_uri_on_window(parent, link, Gtk.get_current_event_time());
  } catch (Error e) {
    Gtk.MessageDialog dlg = new Gtk.MessageDialog(parent, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, _("Could not display %s"), link);
    dlg.format_secondary_text("%s", e.message);
    dlg.run();
    destroy_widget(dlg);
  }
}

public enum ShellEnv {
  NONE,
  GNOME,
  LEGACY
}

private ShellEnv shell = ShellEnv.NONE;
public ShellEnv get_shell()
{
  if (shell == ShellEnv.NONE) {
    // Use Legacy unless we detect a different shell.
    var desktop = Environment.get_variable("XDG_CURRENT_DESKTOP");
    shell = desktop.contains("GNOME") ? ShellEnv.GNOME : ShellEnv.LEGACY;
  }

  return shell;
}

bool user_focused(Gtk.Widget win, Gdk.EventFocus e)
{
  ((Gtk.Window)win).urgency_hint = false;
  win.focus_in_event.disconnect(user_focused);
  return false;
}

public void show_background_window_for_shell(Gtk.Window win)
{
  win.focus_on_map = false;
  win.urgency_hint = true;
  win.focus_in_event.connect(user_focused);
  win.show();
}

public void hide_background_window_for_shell(Gtk.Window win)
{
  win.hide();
}

public void destroy_widget(Gtk.Widget w)
{
  // We destroy in the idle loop for two reasons:
  // 1) Vala likes to unref local dialogs (like file choosers) after we call
  //    destroy, which is odd.  This avoids issues that arise from that.
  // 2) When running in accessiblity mode (as we do during test suites),
  //    GailButtons tend to do odd things with queued events during idle calls.
  //    This avoids destroying objects before gail is done with them, which led
  //    to crashes.
  w.hide();
  w.ref();
  Idle.add(() => {w.destroy(); return false;});
}

public bool gui_initialize(Gtk.Window? parent, bool show_error = true)
{
  string header;
  string msg;
  var rv = DejaDup.initialize(out header, out msg);

  if (!rv && show_error) {
    Gtk.MessageDialog dlg = new Gtk.MessageDialog (parent,
        Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
        Gtk.MessageType.ERROR,
        Gtk.ButtonsType.OK,
        "%s", header);
    dlg.format_secondary_text("%s", msg);
    dlg.run();
    destroy_widget(dlg);
  }

  return rv;
}

} // end namespace
