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

public Gtk.Window? prompt(Gtk.Application app)
{
  DejaDup.update_prompt_time();

  // In GNOME Shell, we show a notification.  Elsewhere, we show a dialog.
  if (DejaDup.get_shell() == DejaDup.ShellEnv.GNOME) {
    show_prompt_notification(app);
    return null;
  }
  else
    return show_prompt_dialog(app);
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
  var rv = _("_Don't Show Again");
  if (!mnemonics)
    rv = rv.replace("_", "");
  return rv;
}

string get_ok_button(bool mnemonics)
{
  var rv = _("_Open Backup Settings");
  if (!mnemonics)
    rv = rv.replace("_", "");
  return rv;
}

void show_prompt_notification(Gtk.Application app)
{
  var note = new Notification(get_header());
  note.set_body(get_body());
  note.set_icon(new ThemedIcon("org.gnome.DejaDup"));
  note.set_default_action("app.prompt-ok");
  note.add_button(get_cancel_button(false), "app.prompt-cancel");
  note.add_button(get_ok_button(false), "app.prompt-ok");
  app.send_notification("prompt", note);
}

Gtk.Window show_prompt_dialog(Gtk.Application app)
{
  var dlg = new Gtk.MessageDialog(null, 0, Gtk.MessageType.INFO,
                                  Gtk.ButtonsType.NONE, "%s", get_header());
  dlg.format_secondary_text("%s", get_body());
  dlg.skip_taskbar_hint = false;
  dlg.set_title(_("Backups"));

  var img = new Gtk.Image.from_icon_name("org.gnome.DejaDup", Gtk.IconSize.DIALOG);
  img.yalign = 0.0f;
  img.show();
  dlg.set_image(img);

  dlg.add_buttons(get_cancel_button(true), Gtk.ResponseType.REJECT,
                  get_ok_button(true), Gtk.ResponseType.ACCEPT);
  dlg.response.connect((dlg, resp) => {
    if (resp == Gtk.ResponseType.REJECT)
      app.activate_action("prompt-cancel", null);
    else if (resp == Gtk.ResponseType.ACCEPT)
      app.activate_action("prompt-ok", null);
    DejaDup.destroy_widget(dlg);
  });

  DejaDup.show_background_window_for_shell(dlg);
  return dlg;
}

