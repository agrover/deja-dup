/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2009 Michael Terry <mike@mterry.name>

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

#ifndef __NAUTILUSEXTENSION_H__
#define __NAUTILUSEXTENSION_H__

#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS


#define TYPE_DEJA_DUP_NAUTILUS_EXTENSION (deja_dup_nautilus_extension_get_type ())
#define DEJA_DUP_NAUTILUS_EXTENSION(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_DEJA_DUP_NAUTILUS_EXTENSION, DejaDupNautilusExtension))
#define DEJA_DUP_NAUTILUS_EXTENSION_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_DEJA_DUP_NAUTILUS_EXTENSION, DejaDupNautilusExtensionClass))
#define IS_DEJA_DUP_NAUTILUS_EXTENSION(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_DEJA_DUP_NAUTILUS_EXTENSION))
#define IS_DEJA_DUP_NAUTILUS_EXTENSION_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_DEJA_DUP_NAUTILUS_EXTENSION))
#define DEJA_DUP_NAUTILUS_EXTENSION_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_DEJA_DUP_NAUTILUS_EXTENSION, DejaDupNautilusExtensionClass))

typedef struct _DejaDupNautilusExtension DejaDupNautilusExtension;
typedef struct _DejaDupNautilusExtensionClass DejaDupNautilusExtensionClass;
typedef struct _DejaDupNautilusExtensionPrivate DejaDupNautilusExtensionPrivate;

struct _DejaDupNautilusExtension {
	GObject parent_instance;
	DejaDupNautilusExtensionPrivate * priv;
};

struct _DejaDupNautilusExtensionClass {
	GObjectClass parent_class;
};


DejaDupNautilusExtension* deja_dup_nautilus_extension_construct (GType object_type);
DejaDupNautilusExtension* deja_dup_nautilus_extension_new (void);
GType deja_dup_nautilus_extension_get_type (void);


G_END_DECLS

#endif
