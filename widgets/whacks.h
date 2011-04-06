/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008–2010 Michael Terry <mike@mterry.name>

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

/* This file is for whatever we can't currently do in Vala. */
#ifndef __WHACKS_H__
#define __WHACKS_H__

#include <gtk/gtk.h>

extern GObject *hacks_status_icon_make_app_indicator (GtkMenu *menu);
extern void hacks_status_icon_close_app_indicator (GObject *icon);

extern GObject *hacks_unity_get_entry(void);
extern void hacks_unity_entry_show_progress(GObject *entry, gboolean show);
extern void hacks_unity_entry_set_progress(GObject *entry, gdouble percent);
extern void hacks_unity_entry_set_menu(GObject *entry, GtkMenu *menu);

#endif

