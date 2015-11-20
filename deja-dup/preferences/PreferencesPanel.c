/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2010 Intel, Inc
    © 2011 Michael Terry <mike@mterry.name>

    Authors: Thomas Wood <thomas.wood@intel.com>
             Rodrigo Moya <rodrigo@gnome.org>

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

#include <gtk/gtk.h>
#include <libunity-control-center/cc-panel.h>
#include "widgets.h"

#define DEJA_DUP_TYPE_PREFERENCES_PANEL deja_dup_preferences_panel_get_type()

typedef struct _DejaDupPreferencesPanel DejaDupPreferencesPanel;
typedef struct _DejaDupPreferencesPanelClass DejaDupPreferencesPanelClass;
typedef struct _DejaDupPreferencesPeriodicSwitch DejaDupPreferencesPeriodicSwitch;

struct _DejaDupPreferencesPanel
{
  CcPanel parent;
  DejaDupPreferencesPeriodicSwitch *auto_switch;
};

struct _DejaDupPreferencesPanelClass
{
  CcPanelClass parent_class;
};

G_DEFINE_DYNAMIC_TYPE (DejaDupPreferencesPanel, deja_dup_preferences_panel, CC_TYPE_PANEL)

extern void* deja_dup_preferences_new (DejaDupPreferencesPeriodicSwitch *auto_switch);
extern DejaDupPreferencesPeriodicSwitch* deja_dup_preferences_periodic_switch_new (void);

static void
deja_dup_preferences_panel_class_finalize (DejaDupPreferencesPanelClass *klass)
{
}

static void
deja_dup_preferences_panel_constructed (GObject *object)
{
  CcPanel *panel = CC_PANEL (object);
  DejaDupPreferencesPanel *self = (DejaDupPreferencesPanel*)object;

  G_OBJECT_CLASS (deja_dup_preferences_panel_parent_class)->constructed (object);

  cc_shell_embed_widget_in_header (cc_panel_get_shell (panel), GTK_WIDGET (self->auto_switch));
}

static const char *
deja_dup_preferences_panel_get_help_uri (CcPanel *panel)
{
  return "help:deja-dup";
}

static void
deja_dup_preferences_panel_class_init (DejaDupPreferencesPanelClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  CcPanelClass *panel_class = CC_PANEL_CLASS (klass);

  object_class->constructed = deja_dup_preferences_panel_constructed;
  panel_class->get_help_uri = deja_dup_preferences_panel_get_help_uri;
}

static void
deja_dup_preferences_panel_init (DejaDupPreferencesPanel *self)
{
  self->auto_switch = deja_dup_preferences_periodic_switch_new ();
  gtk_widget_set_valign (GTK_WIDGET (self->auto_switch), GTK_ALIGN_CENTER);
  gtk_widget_show_all (GTK_WIDGET (self->auto_switch));

  GtkWidget *widget = GTK_WIDGET (deja_dup_preferences_new (self->auto_switch));
  gtk_container_set_border_width (GTK_CONTAINER (widget), 6); // g-c-c adds 6
  gtk_widget_show_all (widget);
  gtk_container_add (GTK_CONTAINER (self), widget);
}

static gboolean
delayed_init ()
{
  deja_dup_gui_initialize(NULL, FALSE);
  return FALSE;
}

void
g_io_module_load (GIOModule *module)
{
  bindtextdomain (GETTEXT_PACKAGE, LOCALE_DIR);
  bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");

  GtkIconTheme *theme = gtk_icon_theme_get_default ();
  gtk_icon_theme_append_search_path (theme, THEME_DIR);

  deja_dup_preferences_panel_register_type (G_TYPE_MODULE (module));
  g_io_extension_point_implement (CC_SHELL_PANEL_EXTENSION_POINT,
                                  DEJA_DUP_TYPE_PREFERENCES_PANEL,
                                  "deja-dup", 0);

  g_idle_add(delayed_init, NULL);
}

void
g_io_module_unload (GIOModule *module)
{
}
