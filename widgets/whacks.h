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
#ifndef __HACKS_H__
#define __HACKS_H__

#include <gtk/gtk.h>

extern GObject *hacks_status_icon_make_app_indicator (GtkMenu *menu);
extern void hacks_status_icon_close_app_indicator (GObject *icon);
extern GtkComboBox *hacks_combo_box_text_new();
extern char *hacks_combo_box_get_text(GtkComboBox *box);
extern long hacks_window_get_xid(GdkWindow *win);
extern int hacks_widget_get_allocated_width(GtkWidget *w);

#endif

