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

#include "type.h"
#include <libnautilus-extension/nautilus-menu-provider.h>

/* I couldn't quite figure out how to get such low-level plumbing into Vala.
 * So there's a bit of crazy-ness here, where I try to do as much as I can
 * in Vala and do a bit of glue in this file.
 */

/* Just include the whole extension to get at some of the non-exported stuff
   like class_init and instance_init */
#include "NautilusExtension.c"

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

  GType deja_dup_nautilus_extension_type = g_type_module_register_type (module,
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

