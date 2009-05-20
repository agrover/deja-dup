/* GTK - The GIMP Toolkit
 * Copyright (C) Christian Kellner <gicmo@gnome.org>

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

/*
 * Modified by the GTK+ Team and others 1997-2000.  See the AUTHORS
 * file for a list of people on the GTK+ Team.  See the ChangeLog
 * files for a list of changes.  These files are distributed with
 * GTK+ at ftp://ftp.gtk.org/pub/gtk/.
 */

#ifndef __DUP_MOUNT_OPERATION_H__
#define __DUP_MOUNT_OPERATION_H__

#include <gio/gio.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

#define DUP_TYPE_MOUNT_OPERATION         (dup_mount_operation_get_type ())
#define DUP_MOUNT_OPERATION(o)           (G_TYPE_CHECK_INSTANCE_CAST ((o), DUP_TYPE_MOUNT_OPERATION, DupMountOperation))
#define DUP_MOUNT_OPERATION_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), DUP_TYPE_MOUNT_OPERATION, DupMountOperationClass))
#define DUP_IS_MOUNT_OPERATION(o)        (G_TYPE_CHECK_INSTANCE_TYPE ((o), DUP_TYPE_MOUNT_OPERATION))
#define DUP_IS_MOUNT_OPERATION_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE ((k), DUP_TYPE_MOUNT_OPERATION))
#define DUP_MOUNT_OPERATION_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS ((o), DUP_TYPE_MOUNT_OPERATION, DupMountOperationClass))

typedef struct _DupMountOperation         DupMountOperation;
typedef struct _DupMountOperationClass    DupMountOperationClass;
typedef struct _DupMountOperationPrivate  DupMountOperationPrivate;

struct _DupMountOperation
{
  GMountOperation parent_instance;

  DupMountOperationPrivate *priv;
};

struct _DupMountOperationClass
{
  GMountOperationClass parent_class;

  /* Padding for future expansion */
  void (*_gtk_reserved1) (void);
  void (*_gtk_reserved2) (void);
  void (*_gtk_reserved3) (void);
  void (*_gtk_reserved4) (void);
};


GType            dup_mount_operation_get_type   (void);
GMountOperation *dup_mount_operation_new        (GtkWindow         *parent);
gboolean         dup_mount_operation_is_showing (DupMountOperation *op);
void             dup_mount_operation_set_parent (DupMountOperation *op,
                                                 GtkWindow         *parent);
GtkWindow *      dup_mount_operation_get_parent (DupMountOperation *op);
void             dup_mount_operation_set_screen (DupMountOperation *op,
                                                 GdkScreen         *screen);
GdkScreen       *dup_mount_operation_get_screen (DupMountOperation *op);

G_END_DECLS

#endif /* __DUP_MOUNT_OPERATION_H__ */
