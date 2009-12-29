/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008, 2009 Michael Terry <mike@mterry.name>

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

void
hacks_status_icon_set_tooltip_text (GtkStatusIcon *icon, const gchar *text)
{
#if GTK_CHECK_VERSION(2, 16, 0)
  return gtk_status_icon_set_tooltip_text (icon, text);
#else
  return gtk_status_icon_set_tooltip (icon, text);
#endif
}

/* This is done in whacks, because we can't encode the #ifdef HAVE_APPINDICATOR
   in vala (we can... but not have it carry through to the compiled C). */
GObject *
hacks_status_icon_make_app_indicator (GtkMenu *menu)
{
#ifdef HAVE_APPINDICATOR
  AppIndicator *icon = app_indicator_new(PACKAGE, "deja-dup-applet", 
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

GtkLabel *
hacks_make_link_label (const gchar *text)
{
#if GTK_CHECK_VERSION(2, 18, 0)
  GtkLabel *label = GTK_LABEL (g_object_ref_sink (gtk_label_new ("")));
  gtk_label_set_markup (label, text);
  gtk_label_set_track_visited_links (label, FALSE);
  return label;
#else
  return NULL;
#endif
}
