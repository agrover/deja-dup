/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2004, 2005 Free Software Foundation, Inc.
    © 2009 Michael Terry <mike@mterry.name>

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

#include "NautilusExtension.h"
#include "config.h"
#include <libnautilus-extension/nautilus-menu-provider.h>
#include <glib/gi18n-lib.h>

static void
make_file_list(NautilusFileInfo *info, GString *str)
{
  GFile *file = nautilus_file_info_get_location(info);
  gchar *uri = g_file_get_uri(file);
  if (str->len)
    g_string_assign(str, uri);
  else
    g_string_append_printf(str, " %s", uri);
  g_free(uri);
  g_object_unref(file);
}

static void
restore_files_callback(NautilusMenuItem *item, GList *files)
{
  GString *str = g_string_new("");
  gchar *cmd;

  g_list_foreach(files, (GFunc)make_file_list, str);
  cmd = g_strdup_printf("deja-dup --restore %s", str->str);

  g_spawn_command_line_async(cmd, NULL);

  g_free(cmd);
  g_string_free(str, TRUE);
  g_list_foreach(files, (GFunc)g_object_unref, NULL);
  g_list_free(files);
}

static GList *
deja_dup_nautilus_extension_get_background_items(NautilusMenuProvider *provider,
                                                 GtkWidget *window,
                                                 NautilusFileInfo *file)
{
  gchar *path;

  if (file == NULL)
    return NULL;

  path = g_find_program_in_path("deja-dup");
  if (!path)
    return NULL;
  g_free(path);

  return NULL;
}

static GList *
deja_dup_nautilus_extension_get_file_items(NautilusMenuProvider *provider,
                                           GtkWidget *window,
                                           GList *files)
{
  NautilusMenuItem *item;
  guint length;
  GList *file_copies;
  gchar *path;

  if (files == NULL)
    return NULL;

  path = g_find_program_in_path("deja-dup");
  if (!path)
    return NULL;
  g_free(path);

  length = g_list_length(files);
  item = nautilus_menu_item_new("DejaDupNautilusExtension::restore_item",
                                dngettext(GETTEXT_PACKAGE,
                                          "Revert to Previous Version...",
                                          "Revert to Previous Versions...",
                                          length),
                                dngettext(GETTEXT_PACKAGE,
                                          "Restore file from backup",
                                          "Restore files from backup",
                                          length),
                                "document-revert");

  file_copies = g_list_copy(files);
  g_list_foreach(file_copies, (GFunc)g_object_ref, NULL);
  g_signal_connect(item, "activate", G_CALLBACK (restore_files_callback), file_copies);

  return g_list_append(NULL, item);
}


enum  {
  DEJA_DUP_NAUTILUS_EXTENSION_DUMMY_PROPERTY
};
static gpointer deja_dup_nautilus_extension_parent_class = NULL;


static GType deja_dup_nautilus_extension_type = 0;


DejaDupNautilusExtension* deja_dup_nautilus_extension_construct (GType object_type) {
  DejaDupNautilusExtension * self;
  self = g_object_newv (object_type, 0, NULL);
  return self;
}


DejaDupNautilusExtension* deja_dup_nautilus_extension_new (void) {
  return deja_dup_nautilus_extension_construct (TYPE_DEJA_DUP_NAUTILUS_EXTENSION);
}


static void deja_dup_nautilus_extension_class_init (DejaDupNautilusExtensionClass * klass) {
  deja_dup_nautilus_extension_parent_class = g_type_class_peek_parent (klass);
}


static void deja_dup_nautilus_extension_instance_init (DejaDupNautilusExtension * self) {
}


GType deja_dup_nautilus_extension_get_type (void) {
  return deja_dup_nautilus_extension_type;
}


static void
deja_dup_nautilus_extension_menu_provider_iface_init (NautilusMenuProviderIface *iface)
{
  iface->get_background_items = deja_dup_nautilus_extension_get_background_items;
  iface->get_file_items = deja_dup_nautilus_extension_get_file_items;
}

void deja_dup_nautilus_extension_register_type (GTypeModule *module)
{
  static const GTypeInfo info = {
    sizeof (DejaDupNautilusExtensionClass),
    (GBaseInitFunc) NULL,
    (GBaseFinalizeFunc) NULL,
    (GClassInitFunc) deja_dup_nautilus_extension_class_init,
    NULL,
    NULL,
    sizeof (DejaDupNautilusExtension),
    0,
    (GInstanceInitFunc) deja_dup_nautilus_extension_instance_init,
  };

  deja_dup_nautilus_extension_type = g_type_module_register_type (module,
    G_TYPE_OBJECT,
    "DejaDupNautilusExtension",
    &info, 0);

  static const GInterfaceInfo menu_provider_iface_info =
  {
    (GInterfaceInitFunc)deja_dup_nautilus_extension_menu_provider_iface_init,
     NULL,
     NULL
  };

  g_type_module_add_interface (module, deja_dup_nautilus_extension_type,
    NAUTILUS_TYPE_MENU_PROVIDER, &menu_provider_iface_info);
}

static GType type_list[1];

void nautilus_module_initialize(GTypeModule *module)
{
  /*g_print("Initializing Déjà Dup extension\n");*/
  deja_dup_nautilus_extension_register_type(module);
  type_list[0] = TYPE_DEJA_DUP_NAUTILUS_EXTENSION;

  bindtextdomain(GETTEXT_PACKAGE, LOCALE_DIR);
  bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
}

void nautilus_module_list_types (const GType **types, int *num_types)
{
  *types = type_list;
  *num_types = G_N_ELEMENTS (type_list);
}

void nautilus_module_shutdown(void)
{
  /*g_print("Shutting down Déjà Dup extension\n");*/
}
