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

extern gchar *hacks_unix_mount_get_fs_type (const gchar *file);
extern void hacks_status_icon_set_tooltip_text (GtkStatusIcon *icon, const gchar *text);

#endif

