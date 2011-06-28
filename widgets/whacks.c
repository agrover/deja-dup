/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
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

#include "config.h"

#ifdef HAVE_APPINDICATOR
#include <libappindicator/app-indicator.h>
#endif

#if HAVE_UNITY
#include <unity.h>
#include <libdbusmenu-gtk3/parser.h>
#endif

#include "whacks.h"

/* This is done in whacks, because we can't encode the #ifdef HAVE_APPINDICATOR
   in vala (we can... but not have it carry through to the compiled C). */
GObject *
hacks_status_icon_make_app_indicator (GtkMenu *menu)
{
#ifdef HAVE_APPINDICATOR
  AppIndicator *icon = app_indicator_new(PACKAGE, NULL, 
                                         APP_INDICATOR_CATEGORY_APPLICATION_STATUS);
  app_indicator_set_icon_full(icon, "deja-dup-symbolic", g_get_application_name());
  app_indicator_set_menu(icon, menu);
  app_indicator_set_status(icon, APP_INDICATOR_STATUS_ACTIVE);
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

gboolean hacks_unity_present(void)
{
#if HAVE_UNITY
  return unity_inspector_get_unity_running(unity_inspector_get_default());
#else
  return FALSE;
#endif
}

GObject *hacks_unity_get_entry(void)
{
#if HAVE_UNITY
  if (hacks_unity_present())
    return G_OBJECT(unity_launcher_entry_get_for_desktop_id("deja-dup.desktop"));
  else
    return NULL;
#else
  return NULL;
#endif
}

void hacks_unity_entry_show_progress(GObject *entry, gboolean show)
{
#if HAVE_UNITY
  if (UNITY_IS_LAUNCHER_ENTRY(entry))
    unity_launcher_entry_set_progress_visible(UNITY_LAUNCHER_ENTRY(entry), show);
#endif
}

void hacks_unity_entry_set_progress(GObject *entry, gdouble percent)
{
#if HAVE_UNITY
  if (UNITY_IS_LAUNCHER_ENTRY(entry))
    unity_launcher_entry_set_progress(UNITY_LAUNCHER_ENTRY(entry), percent);
#endif
}

void hacks_unity_entry_set_menu(GObject *entry, GtkMenu *menu)
{
#if HAVE_UNITY
  if (UNITY_IS_LAUNCHER_ENTRY(entry)) {
    DbusmenuMenuitem *dbusmenu = (menu != NULL) ? dbusmenu_gtk_parse_menu_structure(GTK_WIDGET(menu)) : NULL;
    unity_launcher_entry_set_quicklist(UNITY_LAUNCHER_ENTRY(entry), dbusmenu);
  }
#endif
}

