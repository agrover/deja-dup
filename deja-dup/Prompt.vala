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

public Gtk.Window? prompt()
{
  DejaDup.update_prompt_time();

  // In GNOME Shell, we show a notification.  Elsewhere, we show a dialog.
  if (DejaDup.get_shell() == DejaDup.ShellEnv.GNOME) {
    show_prompt_notification();
    return null;
  }
  else
    return show_prompt_dialog();
}

string get_header()
{
  return _("Keep your files safe by backing up regularly");
}

string get_body()
{
  return _("Important documents, data, and settings can be protected by storing them in a backup. In the case of a disaster, you would be able to recover them from that backup.");
}

string get_cancel_button(bool mnemonics)
{
  if (mnemonics)
    return _("_Don't Show Again");
  else
    return _("Don't Show Again");
}

string get_ok_button(bool mnemonics)
{
  if (mnemonics)
    return _("_Open Backup Settings");
  else
    return _("Open Backup Settings");
}

void cancel()
{
  DejaDup.update_prompt_time(true);
}

void ok()
{
  DejaDup.update_prompt_time(true);

  var app = new DesktopAppInfo("deja-dup-ccpanel.desktop");
  if (app != null) {
    try {
      app.launch(null, Gdk.Screen.get_default().get_display().get_app_launch_context());
      return;
    }
    catch (Error e) {
      // ignore, may just be gnome-control-center not being installed
    }
  }

  // fallback to normal preference window
  app = new DesktopAppInfo("deja-dup-preferences.desktop");
  try {
    app.launch(null, Gdk.Screen.get_default().get_display().get_app_launch_context());
  }
  catch (Error e) {
    warning("%s\n", e.message);
  }
}

void show_prompt_notification()
{
  Notify.init(_("Backup"));
  var note = new Notify.Notification(get_header(), get_body(), "deja-dup");
  note.add_action("cancel", get_cancel_button(false), () => {
    cancel();
    try {
      note.close();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  });
  note.add_action("ok", get_ok_button(false), () => {
    ok();
    try {
      note.close();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  });
  try {
    note.show();
  }
  catch (Error e) {
    warning("%s\n", e.message);
  }
}

Gtk.Window show_prompt_dialog()
{
  var dlg = new Gtk.MessageDialog(null, 0, Gtk.MessageType.INFO,
                                  Gtk.ButtonsType.NONE, "%s", get_header());
  dlg.format_secondary_text("%s", get_body());
  dlg.skip_taskbar_hint = false;
  dlg.set_title(_("Backup"));

  var img = new Gtk.Image.from_icon_name("deja-dup", Gtk.IconSize.DIALOG);
  img.yalign = 0.0f;
  img.show();
  dlg.set_image(img);

  dlg.add_buttons(get_cancel_button(true), Gtk.ResponseType.REJECT,
                  get_ok_button(true), Gtk.ResponseType.ACCEPT);
  dlg.response.connect((dlg, resp) => {
    if (resp == Gtk.ResponseType.REJECT)
      cancel();
    else if (resp == Gtk.ResponseType.ACCEPT)
      ok();
    DejaDup.destroy_widget(dlg);
  });

  DejaDup.show_background_window_for_shell(dlg);
  return dlg;
}

