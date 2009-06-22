/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008, 2009 Michael Terry <mike@mterry.name>

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

#include <gio/gunixmounts.h>
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

/**
 * At the time of this writing, vala 0.7.1's gio-unix-2.0 bindings are crap.
 * This function grabs a unix mount's filesystem type (vfat, ecryptfs, etc)
 */
gchar *
hacks_unix_mount_get_fs_type (const gchar *file)
{
  GUnixMountEntry *mount = g_unix_mount_at(file, NULL);
  gchar *fs_type = g_strdup(g_unix_mount_get_fs_type(mount));
  g_unix_mount_free(mount);
  return fs_type;
}

void
hacks_status_icon_set_tooltip_text (GtkStatusIcon *icon, const gchar *text)
{
#if GTK_CHECK_VERSION(2, 16, 0)
  return gtk_status_icon_set_tooltip_text (icon, text);
#else
  return gtk_status_icon_set_tooltip (icon, text);
#endif
}

