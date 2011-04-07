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
#include <libgnome-control-center/cc-panel.h>
#include "preferences.h"
#include "config.h"

#define DEJA_DUP_TYPE_PREFERENCES_PANEL deja_dup_preferences_panel_get_type()

#define DEJA_DUP_PREFERENCES_PANEL(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
  DEJA_DUP_TYPE_PREFERENCES_PANEL, DejaDupPreferencesPanel))

#define DEJA_DUP_PREFERENCES_PANEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), \
  DEJA_DUP_TYPE_PREFERENCES_PANEL, DejaDupPreferencesPanelClass))

#define CC_IS_MOUSE_PANEL(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
  DEJA_DUP_TYPE_PREFERENCES_PANEL))

#define CC_IS_MOUSE_PANEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), \
  DEJA_DUP_TYPE_PREFERENCES_PANEL))

#define DEJA_DUP_PREFERENCES_PANEL_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), \
  DEJA_DUP_TYPE_PREFERENCES_PANEL, DejaDupPreferencesPanelClass))

typedef struct _DejaDupPreferencesPanel DejaDupPreferencesPanel;
typedef struct _DejaDupPreferencesPanelClass DejaDupPreferencesPanelClass;
typedef struct _DejaDupPreferencesPanelPrivate DejaDupPreferencesPanelPrivate;

struct _DejaDupPreferencesPanel
{
  CcPanel parent;

  DejaDupPreferencesPanelPrivate *priv;
};

struct _DejaDupPreferencesPanelClass
{
  CcPanelClass parent_class;
};

G_DEFINE_DYNAMIC_TYPE (DejaDupPreferencesPanel, deja_dup_preferences_panel, CC_TYPE_PANEL)

#define PREFERENCES_PANEL_PRIVATE(o) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((o), DEJA_DUP_TYPE_PREFERENCES_PANEL, DejaDupPreferencesPanelPrivate))

struct _DejaDupPreferencesPanelPrivate
{
  GtkWidget  *widget;
};

static void
deja_dup_preferences_panel_dispose (GObject *object)
{
  DejaDupPreferencesPanelPrivate *priv = DEJA_DUP_PREFERENCES_PANEL (object)->priv;

  if (priv->widget)
    {
      g_object_unref (priv->widget);
      priv->widget = NULL;
    }

  G_OBJECT_CLASS (deja_dup_preferences_panel_parent_class)->dispose (object);
}

static void
deja_dup_preferences_panel_class_finalize (DejaDupPreferencesPanelClass *klass)
{
}

static void
deja_dup_preferences_panel_class_init (DejaDupPreferencesPanelClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (DejaDupPreferencesPanelPrivate));

  object_class->dispose = deja_dup_preferences_panel_dispose;
}

static void
deja_dup_preferences_panel_init (DejaDupPreferencesPanel *self)
{
  DejaDupPreferencesPanelPrivate *priv;

  priv = self->priv = PREFERENCES_PANEL_PRIVATE (self);

  priv->widget = GTK_WIDGET (deja_dup_preferences_new ());

  gtk_container_add (GTK_CONTAINER (self), priv->widget);
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
}

void
g_io_module_unload (GIOModule *module)
{
}
