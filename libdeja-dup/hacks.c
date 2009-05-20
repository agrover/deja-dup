/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008 Michael Terry <mike@mterry.name>
    © 2002, 2003, 2006, 2007 Red Hat, Inc.

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

#include <gio/gunixmounts.h>
#include "hacks.h"
#include "mountoperation.h"

static const GnomeKeyringPasswordSchema PASSPHRASE_SCHEMA_DEF = {
  GNOME_KEYRING_ITEM_GENERIC_SECRET,
  {
    {"owner", GNOME_KEYRING_ATTRIBUTE_TYPE_STRING},
    {"type", GNOME_KEYRING_ATTRIBUTE_TYPE_STRING},
    {NULL, 0}
  }
};

const GnomeKeyringPasswordSchema *PASSPHRASE_SCHEMA = &PASSPHRASE_SCHEMA_DEF;

guint32
hacks_status_icon_get_x11_window_id (GtkStatusIcon *icon)
{
#if GTK_CHECK_VERSION(2, 14, 0)
  return gtk_status_icon_get_x11_window_id (icon);
#else
  return 0;
#endif
}

gboolean
hacks_show_uri (const gchar *uri, GError **error)
{
#if GTK_CHECK_VERSION(2, 14, 0)
  return gtk_show_uri (NULL, uri, GDK_CURRENT_TIME, error);
#else
  GAppLaunchContext *context = g_app_launch_context_new ();
  g_app_info_launch_default_for_uri (uri, context, error);
  g_object_unref (context);
  if (error)
    return FALSE;
  return TRUE;
#endif
}

GdkPixbuf *
hacks_get_icon_at_size (const gchar *name, gint size, GError **error)
{
#if GTK_CHECK_VERSION(2, 14, 0)
  return gtk_icon_theme_load_icon (gtk_icon_theme_get_default (), name, size,
                                   GTK_ICON_LOOKUP_FORCE_SIZE, error);
#else
  /* Copyright (C) 2002, 2003 Red Hat, Inc. */
  GdkPixbuf *source_pixbuf, *pixbuf;
  gint image_width, image_height, image_size;
  gdouble scale;
  
  source_pixbuf = gtk_icon_theme_load_icon (gtk_icon_theme_get_default (),
                                            name, size, 0, error);
  if (error)
    return NULL;
  
  /* Do scale calculations that depend on the image size
   */
  image_width = gdk_pixbuf_get_width (source_pixbuf);
  image_height = gdk_pixbuf_get_height (source_pixbuf);

  image_size = MAX (image_width, image_height);
  if (image_size > 0)
    scale = (gdouble)size / (gdouble)image_size;
  else
    scale = 1.0;
  
  if (scale == 1.0)
    pixbuf = source_pixbuf;
  else {
    pixbuf = gdk_pixbuf_scale_simple (source_pixbuf,
                                      0.5 + image_width * scale,
                                      0.5 + image_height * scale,
                                      GDK_INTERP_BILINEAR);
    g_object_unref (source_pixbuf);
  }
  
  return pixbuf;
#endif
}

gboolean
hacks_file_make_directory_with_parents (GFile *file, GError **error)
{
#if GLIB_CHECK_VERSION(2, 18, 0)
  return g_file_make_directory_with_parents (file, NULL, error);
#else
  /* Copyright (C) 2006-2007 Red Hat, Inc. */
  gboolean result;
  GFile *parent_file, *work_file;
  GList *list = NULL, *l;
  GError *my_error = NULL;

  result = g_file_make_directory (file, NULL, &my_error);
  if (result || my_error->code != G_IO_ERROR_NOT_FOUND) 
    {
      if (my_error)
        g_propagate_error (error, my_error);
      return result;
    }
  
  work_file = file;
  
  while (!result && my_error->code == G_IO_ERROR_NOT_FOUND) 
    {
      g_clear_error (&my_error);
    
      parent_file = g_file_get_parent (work_file);
      if (parent_file == NULL)
        break;
      result = g_file_make_directory (parent_file, NULL, &my_error);
    
      if (!result && my_error->code == G_IO_ERROR_NOT_FOUND)
        list = g_list_prepend (list, parent_file);

      work_file = parent_file;
    }

  for (l = list; result && l; l = l->next)
    {
      result = g_file_make_directory ((GFile *) l->data, NULL, &my_error);
    }
  
  /* Clean up */
  while (list != NULL) 
    {
      g_object_unref ((GFile *) list->data);
      list = g_list_remove (list, list->data);
    }

  if (!result) 
    {
      g_propagate_error (error, my_error);
      return result;
    }
  
  return g_file_make_directory (file, NULL, error);
#endif
}

GFileType
hacks_file_query_file_type (GFile *file, GFileQueryInfoFlags flags)
{
#if GLIB_CHECK_VERSION(2, 18, 0)
  return g_file_query_file_type (file, flags, NULL);
#else
  /* Copyright (C) 2006-2007 Red Hat, Inc. */
  GFileInfo *info;
  GFileType file_type;
  
  g_return_val_if_fail (G_IS_FILE(file), G_FILE_TYPE_UNKNOWN);
  info = g_file_query_info (file, G_FILE_ATTRIBUTE_STANDARD_TYPE, flags,
                            NULL, NULL);
  if (info != NULL)
    {
      file_type = g_file_info_get_file_type (info);
      g_object_unref (info);
    }
  else
    file_type = G_FILE_TYPE_UNKNOWN;
  
  return file_type;
#endif
}

/**
 * At the time of this writing, vala 0.7.1's gio-unix-2.0 bindings are crap.
 * This function grabs a unix mount's filesystem type (vfat, ecryptfs, etc)
 */
gchar *
hacks_unix_mount_get_fs_type (const gchar *file)
{
  GUnixMountEntry *mount = g_unix_mount_at(file, NULL);
  gchar *fs_type = g_strdup(g_unix_mount_get_fs_type(mount));
  g_unix_mount_free(mount);
  return fs_type;
}

void
hacks_status_icon_set_tooltip_text (GtkStatusIcon *icon, const gchar *text)
{
#if GTK_CHECK_VERSION(2, 16, 0)
  return gtk_status_icon_set_tooltip_text (icon, text);
#else
  return gtk_status_icon_set_tooltip (icon, text);
#endif
}

GdkWindow *
hacks_widget_get_window (GtkWidget *widget)
{
#if GTK_CHECK_VERSION(2, 14, 0)
  return gtk_widget_get_window (widget);
#else
  return widget->window;
#endif
}

GMountOperation *
hacks_mount_operation_new (GtkWindow *parent)
{
#if GTK_CHECK_VERSION(2, 14, 0)
  return gtk_mount_operation_new (parent);
#else
  return dup_mount_operation_new (parent);
#endif
}

