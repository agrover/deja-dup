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

[CCode (header_file = "NautilusExtension.h")]
extern void deja_dup_nautilus_extension_register_type(TypeModule module);

Type[] type_list;

void nautilus_module_initialize(TypeModule module)
{
	print("Initializing deja-dup Extension\n");
	deja_dup_nautilus_extension_register_type(module);
	type_list = new Type[1];
	type_list[0] = typeof(DejaDupNautilusExtension);
}

void nautilus_module_list_types(out weak Type[] types)
{
	types = type_list;
}

void nautilus_module_shutdown()
{
	print("Shutting down deja-dup Extension\n");
  type_list = null;
}

