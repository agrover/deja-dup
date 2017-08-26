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

public class ConfigLocationGoa : ConfigLocationTable
{
  public Goa.Account account {get; construct;}

  public ConfigLocationGoa(Gtk.SizeGroup sg, FilteredSettings settings, Goa.Account? account) {
    Object(label_sizes: sg, settings: settings, account: account);
  }

  Gtk.Grid hint;
  Gtk.Label label;

  construct {
    add_widget(_("_Folder"),
               new ConfigFolder(DejaDup.GOA_FOLDER_KEY, DejaDup.GOA_ROOT, settings));

    // Add optional widget that warns if the account has Files disabled
    create_hint();

    notify["account"].connect(connect_account);
    connect_account();
  }

  void connect_account()
  {
    if (account != null)
      account.notify["files-disabled"].connect(check_goa);
    check_goa();
  }

  void check_goa()
  {
    if (account == null) {
      label.set_markup("<b><big>%s</big></b>".printf(_("This account is not yet configured. It cannot be used until you add it to your Online Accounts.")));
      hint.visible = true;
    } else if (account.files_disabled) {
      // Translators: 'Files' here refers to the feature label in GNOME Online Accounts
      label.set_markup("<b><big>%s</big></b>".printf(_("This account has disabled Files support. It cannot be used until Files support is enabled again for this Online Account.")));
      hint.visible = true;
    } else {
      hint.visible = false;
    }
  }

  void create_hint()
  {
    hint = new Gtk.Grid();
    hint.row_spacing = 24;
    hint.column_spacing = 12;
    hint.border_width = 12;
    hint.margin_top = 12;
    hint.halign = Gtk.Align.CENTER;
    add_wide_widget(hint);

    var icon = new Gtk.Image.from_icon_name("dialog-warning-symbolic", Gtk.IconSize.DIALOG);
    icon.valign = Gtk.Align.CENTER;
    hint.attach(icon, 0, 0, 1, 1);

    label = new Gtk.Label("");
    label.wrap = true;
    label.max_width_chars = 50;
    label.valign = Gtk.Align.START;
    hint.attach(label, 1, 0, 1, 1);

    if (Environment.find_program_in_path("gnome-control-center") != null) {
      var button = new Gtk.Button.with_mnemonic(_("_Open Online Account Settings"));
      button.hexpand = false;
      button.halign = Gtk.Align.CENTER;
      button.clicked.connect(() => {
        try {
          Process.spawn_async(null, {"gnome-control-center", "online-accounts"}, null,
                              SpawnFlags.STDOUT_TO_DEV_NULL |
                              SpawnFlags.STDERR_TO_DEV_NULL |
                              SpawnFlags.SEARCH_PATH,
                              null, null);
        } catch (Error e) {warning("%s", e.message);}
      });
      hint.attach(button, 0, 1, 2, 1);
    }

    hint.show_all();
    hint.no_show_all = true;
  }
}

}

