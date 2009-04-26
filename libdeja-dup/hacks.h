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

/* This file is for whatever we can't currently do in Vala. */
#ifndef __HACKS_H__
#define __HACKS_H__

#include <gnome-keyring.h>
#include <gtk/gtk.h>
#include <gio/gio.h>

extern const GnomeKeyringPasswordSchema *PASSPHRASE_SCHEMA;

extern guint32 hacks_status_icon_get_x11_window_id (GtkStatusIcon *icon);
extern gboolean hacks_show_uri (const gchar *uri, GError **error);
extern gboolean hacks_file_make_directory_with_parents (GFile *file, GError **error);
extern GdkPixbuf *hacks_get_icon_at_size (const gchar *name, gint size, GError **error);
extern GFileType hacks_file_query_file_type (GFile *file, GFileQueryInfoFlags flags);
extern gchar *hacks_unix_mount_get_fs_type (const gchar *file);

#endif

