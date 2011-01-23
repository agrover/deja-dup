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

#include "config.h"

#ifdef HAVE_APPINDICATOR
#include <libappindicator/app-indicator.h>
#endif

#include "whacks.h"

/* This is done in whacks, because we can't encode the #ifdef HAVE_APPINDICATOR
   in vala (we can... but not have it carry through to the compiled C). */
GObject *
hacks_status_icon_make_app_indicator (GtkMenu *menu)
{
#ifdef HAVE_APPINDICATOR
  AppIndicator *icon = app_indicator_new(PACKAGE, "deja-dup-symbolic", 
                                         APP_INDICATOR_CATEGORY_APPLICATION_STATUS);
  app_indicator_set_status(icon, APP_INDICATOR_STATUS_ACTIVE);
  app_indicator_set_menu(icon, menu);
  return G_OBJECT(icon);
#else
  return NULL;
#endif
}

void
hacks_status_icon_close_app_indicator (GObject *icon)
{
#ifdef HAVE_APPINDICATOR
  app_indicator_set_status(APP_INDICATOR(icon), APP_INDICATOR_STATUS_PASSIVE);
#endif
}

GtkComboBox *
hacks_combo_box_text_new()
{
#if GTK_CHECK_VERSION(2, 23, 90)
  return (GtkComboBox*)g_object_ref_sink(gtk_combo_box_text_new());
#else
  return (GtkComboBox*)g_object_ref_sink(gtk_combo_box_new_text());
#endif
}

char *
hacks_combo_box_get_text(GtkComboBox *box)
{
#if GTK_CHECK_VERSION(2, 23, 90)
  return gtk_combo_box_text_get_active_text((GtkComboBoxText*)box);
#else
  return gtk_combo_box_get_active_text(box);
#endif
}

long
hacks_window_get_xid(GdkWindow *window)
{
#if GTK_CHECK_VERSION(2, 91, 0)
  return gdk_x11_window_get_xid(window);
#else
  return gdk_x11_drawable_get_xid(window);
#endif
}

int
hacks_widget_get_allocated_width(GtkWidget *w)
{
#if GTK_CHECK_VERSION(2, 91, 0)
  return gtk_widget_get_allocated_width(w);
#else
  GtkAllocation a;
  gtk_widget_get_allocation(w, &a);
  return a.width;
#endif
}

void
hacks_widget_destroy(GtkWidget *w)
{
#if GTK_CHECK_VERSION(2, 91, 0)
  gtk_widget_destroy(w);
#else
  gtk_object_destroy((GtkObject*)w);
#endif
}

void
hacks_quit_on_destroy(GtkWidget *w)
{
  // Done as a hack because 2.0 and 3.0 have the signal on different classes,
  // so vala generates code that can't compile with both
  g_signal_connect (w, "destroy", (GCallback)gtk_main_quit, NULL);
}

void
hacks_get_natural_size(GtkWidget *w, GtkRequisition *req)
{
#if GTK_CHECK_VERSION(2, 91, 0)
  gtk_widget_get_preferred_size(w, NULL, req);
#else
  gtk_widget_size_request(w, req);
#endif
}
