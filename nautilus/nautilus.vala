void nautilus_module_list_types (const GType **types, int *num_types)
{
	*types = provider_types;
	*num_types = G_N_ELEMENTS (provider_types);
}

void deja_dup_extension_register_type (GTypeModule *module)
{
  static const GTypeInfo info = {
    sizeof (DejaDupNautilusExtensionClass),
    (GBaseInitFunc) NULL,
    (GBaseFinalizeFunc) NULL,
    (GClassInitFunc) deja_dup_extension_class_init,
    NULL,
    NULL,
    sizeof (DejaDupNautilusExtension),
    0,
    (GInstanceInitFunc) deja_dup_extension_instance_init,
  };

  deja_dup_extension_type = g_type_module_register_type (module,
		G_TYPE_OBJECT,
		"DejaDupNautilusExtension",
		&info, 0);

	/* Nautilus Menu Provider Interface */
	static const GInterfaceInfo menu_provider_iface_info =
	{
		(GInterfaceInitFunc)deja_dup_extension_menu_provider_iface_init,
		 NULL,
		 NULL
	};

	g_type_module_add_interface (module, deja_dup_extension_type,
		NAUTILUS_TYPE_MENU_PROVIDER, &menu_provider_iface_info);

	/* Nautilus Info Provider Interface code could be added here */
	/* Nautilus Property Page Interface code could be added here */
	/* Nautilus Column Provider Interface code could be added here */
}

void nautilus_module_initialize (GTypeModule  *module)
{
	g_print("Initializing Extension\n");
	deja_dup_extension_register_type (module);
	provider_types[0] = deja_dup_extension_get_type ();
}

void nautilus_module_shutdown (void)
{
	g_print("Shutting down Extension\n");
	/* Any module-specific shutdown code*/
}
