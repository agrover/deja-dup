/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008 Michael Terry <mike@mterry.name>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "hacks.h"

static const GnomeKeyringPasswordSchema PASSPHRASE_SCHEMA_DEF = {
  GNOME_KEYRING_ITEM_GENERIC_SECRET,
  {
    {"owner", GNOME_KEYRING_ATTRIBUTE_TYPE_STRING},
    {"type", GNOME_KEYRING_ATTRIBUTE_TYPE_STRING},
    {NULL, 0}
  }
};

const GnomeKeyringPasswordSchema *PASSPHRASE_SCHEMA = &PASSPHRASE_SCHEMA_DEF;

/* FIXME: We should be able to pass gtk_status_icon_position_menu function
 * to popup to position the menu correctly, but bug 562725
 * (http://bugzilla.gnome.org/show_bug.cgi?id=562725) is getting in the
 * way.  For now, we use a C hack.
 */
void hacks_menu_popup(GtkStatusIcon *icon, GtkMenu *menu,
                      guint button, guint activate_time)
{
  gtk_menu_popup(menu, NULL, NULL, gtk_status_icon_position_menu, icon,
                 button, activate_time);
}

