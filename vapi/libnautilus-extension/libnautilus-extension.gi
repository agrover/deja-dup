<?xml version="1.0"?>
<api version="1.0">
	<namespace name="Nautilus">
		<function name="module_initialize" symbol="nautilus_module_initialize">
			<return-type type="void"/>
			<parameters>
				<parameter name="module" type="GTypeModule*"/>
			</parameters>
		</function>
		<function name="module_list_types" symbol="nautilus_module_list_types">
			<return-type type="void"/>
			<parameters>
				<parameter name="types" type="GType**"/>
				<parameter name="num_types" type="int*"/>
			</parameters>
		</function>
		<function name="module_shutdown" symbol="nautilus_module_shutdown">
			<return-type type="void"/>
		</function>
		<callback name="NautilusInfoProviderUpdateComplete">
			<return-type type="void"/>
			<parameters>
				<parameter name="provider" type="NautilusInfoProvider*"/>
				<parameter name="handle" type="NautilusOperationHandle*"/>
				<parameter name="result" type="NautilusOperationResult"/>
				<parameter name="user_data" type="gpointer"/>
			</parameters>
		</callback>
		<struct name="NautilusColumnDetails">
		</struct>
		<struct name="NautilusFile">
		</struct>
		<struct name="NautilusFileInfo">
			<method name="add_emblem" symbol="nautilus_file_info_add_emblem">
				<return-type type="void"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
					<parameter name="emblem_name" type="char*"/>
				</parameters>
			</method>
			<method name="add_string_attribute" symbol="nautilus_file_info_add_string_attribute">
				<return-type type="void"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
					<parameter name="attribute_name" type="char*"/>
					<parameter name="value" type="char*"/>
				</parameters>
			</method>
			<method name="can_write" symbol="nautilus_file_info_can_write">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_activation_uri" symbol="nautilus_file_info_get_activation_uri">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_file_type" symbol="nautilus_file_info_get_file_type">
				<return-type type="GFileType"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_location" symbol="nautilus_file_info_get_location">
				<return-type type="GFile*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_mime_type" symbol="nautilus_file_info_get_mime_type">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_mount" symbol="nautilus_file_info_get_mount">
				<return-type type="GMount*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_name" symbol="nautilus_file_info_get_name">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_parent_info" symbol="nautilus_file_info_get_parent_info">
				<return-type type="NautilusFileInfo*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_parent_location" symbol="nautilus_file_info_get_parent_location">
				<return-type type="GFile*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_parent_uri" symbol="nautilus_file_info_get_parent_uri">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_string_attribute" symbol="nautilus_file_info_get_string_attribute">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
					<parameter name="attribute_name" type="char*"/>
				</parameters>
			</method>
			<method name="get_uri" symbol="nautilus_file_info_get_uri">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_uri_scheme" symbol="nautilus_file_info_get_uri_scheme">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="invalidate_extension_info" symbol="nautilus_file_info_invalidate_extension_info">
				<return-type type="void"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="is_directory" symbol="nautilus_file_info_is_directory">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="is_gone" symbol="nautilus_file_info_is_gone">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="is_mime_type" symbol="nautilus_file_info_is_mime_type">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
					<parameter name="mime_type" type="char*"/>
				</parameters>
			</method>
			<method name="list_copy" symbol="nautilus_file_info_list_copy">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="files" type="GList*"/>
				</parameters>
			</method>
			<method name="list_free" symbol="nautilus_file_info_list_free">
				<return-type type="void"/>
				<parameters>
					<parameter name="files" type="GList*"/>
				</parameters>
			</method>
		</struct>
		<struct name="NautilusMenuItemDetails">
		</struct>
		<struct name="NautilusOperationHandle">
		</struct>
		<struct name="NautilusPropertyPageDetails">
		</struct>
		<enum name="NautilusOperationResult" type-name="NautilusOperationResult" get-type="nautilus_operation_result_get_type">
			<member name="NAUTILUS_OPERATION_COMPLETE" value="0"/>
			<member name="NAUTILUS_OPERATION_FAILED" value="1"/>
			<member name="NAUTILUS_OPERATION_IN_PROGRESS" value="2"/>
		</enum>
		<object name="NautilusColumn" parent="GObject" type-name="NautilusColumn" get-type="nautilus_column_get_type">
			<constructor name="new" symbol="nautilus_column_new">
				<return-type type="NautilusColumn*"/>
				<parameters>
					<parameter name="name" type="char*"/>
					<parameter name="attribute" type="char*"/>
					<parameter name="label" type="char*"/>
					<parameter name="description" type="char*"/>
				</parameters>
			</constructor>
			<property name="attribute" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="attribute-q" type="guint" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="description" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="label" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="name" type="char*" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="xalign" type="gfloat" readable="1" writable="1" construct="0" construct-only="0"/>
			<field name="details" type="NautilusColumnDetails*"/>
		</object>
		<object name="NautilusMenu" parent="GObject" type-name="NautilusMenu" get-type="nautilus_menu_get_type">
			<method name="append_item" symbol="nautilus_menu_append_item">
				<return-type type="void"/>
				<parameters>
					<parameter name="this" type="NautilusMenu*"/>
					<parameter name="item" type="NautilusMenuItem*"/>
				</parameters>
			</method>
			<method name="get_items" symbol="nautilus_menu_get_items">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="this" type="NautilusMenu*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="nautilus_menu_new">
				<return-type type="NautilusMenu*"/>
			</constructor>
		</object>
		<object name="NautilusMenuItem" parent="GObject" type-name="NautilusMenuItem" get-type="nautilus_menu_item_get_type">
			<method name="activate" symbol="nautilus_menu_item_activate">
				<return-type type="void"/>
				<parameters>
					<parameter name="item" type="NautilusMenuItem*"/>
				</parameters>
			</method>
			<method name="list_free" symbol="nautilus_menu_item_list_free">
				<return-type type="void"/>
				<parameters>
					<parameter name="item_list" type="GList*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="nautilus_menu_item_new">
				<return-type type="NautilusMenuItem*"/>
				<parameters>
					<parameter name="name" type="char*"/>
					<parameter name="label" type="char*"/>
					<parameter name="tip" type="char*"/>
					<parameter name="icon" type="char*"/>
				</parameters>
			</constructor>
			<method name="set_submenu" symbol="nautilus_menu_item_set_submenu">
				<return-type type="void"/>
				<parameters>
					<parameter name="item" type="NautilusMenuItem*"/>
					<parameter name="menu" type="NautilusMenu*"/>
				</parameters>
			</method>
			<property name="icon" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="label" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="menu" type="NautilusMenu*" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="name" type="char*" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="priority" type="gboolean" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="sensitive" type="gboolean" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="tip" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
			<signal name="activate" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="item" type="NautilusMenuItem*"/>
				</parameters>
			</signal>
			<field name="details" type="NautilusMenuItemDetails*"/>
		</object>
		<object name="NautilusPropertyPage" parent="GObject" type-name="NautilusPropertyPage" get-type="nautilus_property_page_get_type">
			<constructor name="new" symbol="nautilus_property_page_new">
				<return-type type="NautilusPropertyPage*"/>
				<parameters>
					<parameter name="name" type="char*"/>
					<parameter name="label" type="GtkWidget*"/>
					<parameter name="page" type="GtkWidget*"/>
				</parameters>
			</constructor>
			<property name="label" type="GtkWidget*" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="name" type="char*" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="page" type="GtkWidget*" readable="1" writable="1" construct="0" construct-only="0"/>
			<field name="details" type="NautilusPropertyPageDetails*"/>
		</object>
		<interface name="NautilusColumnProvider" type-name="NautilusColumnProvider" get-type="nautilus_column_provider_get_type">
			<requires>
				<interface name="GObject"/>
			</requires>
			<method name="get_columns" symbol="nautilus_column_provider_get_columns">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="provider" type="NautilusColumnProvider*"/>
				</parameters>
			</method>
			<vfunc name="get_columns">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="provider" type="NautilusColumnProvider*"/>
				</parameters>
			</vfunc>
		</interface>
		<interface name="NautilusFileInfo" type-name="NautilusFileInfo" get-type="nautilus_file_info_get_type">
			<requires>
				<interface name="GObject"/>
			</requires>
			<vfunc name="add_emblem">
				<return-type type="void"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
					<parameter name="emblem_name" type="char*"/>
				</parameters>
			</vfunc>
			<vfunc name="add_string_attribute">
				<return-type type="void"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
					<parameter name="attribute_name" type="char*"/>
					<parameter name="value" type="char*"/>
				</parameters>
			</vfunc>
			<vfunc name="can_write">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_activation_uri">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_file_type">
				<return-type type="GFileType"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_location">
				<return-type type="GFile*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_mime_type">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_mount">
				<return-type type="GMount*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_name">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_parent_info">
				<return-type type="NautilusFileInfo*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_parent_location">
				<return-type type="GFile*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_parent_uri">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_string_attribute">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
					<parameter name="attribute_name" type="char*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_uri">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_uri_scheme">
				<return-type type="char*"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="invalidate_extension_info">
				<return-type type="void"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="is_directory">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="is_gone">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="is_mime_type">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="file" type="NautilusFileInfo*"/>
					<parameter name="mime_Type" type="char*"/>
				</parameters>
			</vfunc>
		</interface>
		<interface name="NautilusInfoProvider" type-name="NautilusInfoProvider" get-type="nautilus_info_provider_get_type">
			<requires>
				<interface name="GObject"/>
			</requires>
			<method name="cancel_update" symbol="nautilus_info_provider_cancel_update">
				<return-type type="void"/>
				<parameters>
					<parameter name="provider" type="NautilusInfoProvider*"/>
					<parameter name="handle" type="NautilusOperationHandle*"/>
				</parameters>
			</method>
			<method name="update_complete_invoke" symbol="nautilus_info_provider_update_complete_invoke">
				<return-type type="void"/>
				<parameters>
					<parameter name="update_complete" type="GClosure*"/>
					<parameter name="provider" type="NautilusInfoProvider*"/>
					<parameter name="handle" type="NautilusOperationHandle*"/>
					<parameter name="result" type="NautilusOperationResult"/>
				</parameters>
			</method>
			<method name="update_file_info" symbol="nautilus_info_provider_update_file_info">
				<return-type type="NautilusOperationResult"/>
				<parameters>
					<parameter name="provider" type="NautilusInfoProvider*"/>
					<parameter name="file" type="NautilusFileInfo*"/>
					<parameter name="update_complete" type="GClosure*"/>
					<parameter name="handle" type="NautilusOperationHandle**"/>
				</parameters>
			</method>
			<vfunc name="cancel_update">
				<return-type type="void"/>
				<parameters>
					<parameter name="provider" type="NautilusInfoProvider*"/>
					<parameter name="handle" type="NautilusOperationHandle*"/>
				</parameters>
			</vfunc>
			<vfunc name="update_file_info">
				<return-type type="NautilusOperationResult"/>
				<parameters>
					<parameter name="provider" type="NautilusInfoProvider*"/>
					<parameter name="file" type="NautilusFileInfo*"/>
					<parameter name="update_complete" type="GClosure*"/>
					<parameter name="handle" type="NautilusOperationHandle**"/>
				</parameters>
			</vfunc>
		</interface>
		<interface name="NautilusLocationWidgetProvider" type-name="NautilusLocationWidgetProvider" get-type="nautilus_location_widget_provider_get_type">
			<requires>
				<interface name="GObject"/>
			</requires>
			<method name="get_widget" symbol="nautilus_location_widget_provider_get_widget">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="provider" type="NautilusLocationWidgetProvider*"/>
					<parameter name="uri" type="char*"/>
					<parameter name="window" type="GtkWidget*"/>
				</parameters>
			</method>
			<vfunc name="get_widget">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="provider" type="NautilusLocationWidgetProvider*"/>
					<parameter name="uri" type="char*"/>
					<parameter name="window" type="GtkWidget*"/>
				</parameters>
			</vfunc>
		</interface>
		<interface name="NautilusMenuProvider" type-name="NautilusMenuProvider" get-type="nautilus_menu_provider_get_type">
			<requires>
				<interface name="GObject"/>
			</requires>
			<method name="emit_items_updated_signal" symbol="nautilus_menu_provider_emit_items_updated_signal">
				<return-type type="void"/>
				<parameters>
					<parameter name="provider" type="NautilusMenuProvider*"/>
				</parameters>
			</method>
			<method name="get_background_items" symbol="nautilus_menu_provider_get_background_items">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="provider" type="NautilusMenuProvider*"/>
					<parameter name="window" type="GtkWidget*"/>
					<parameter name="current_folder" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<method name="get_file_items" symbol="nautilus_menu_provider_get_file_items">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="provider" type="NautilusMenuProvider*"/>
					<parameter name="window" type="GtkWidget*"/>
					<parameter name="files" type="GList*"/>
				</parameters>
			</method>
			<method name="get_toolbar_items" symbol="nautilus_menu_provider_get_toolbar_items">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="provider" type="NautilusMenuProvider*"/>
					<parameter name="window" type="GtkWidget*"/>
					<parameter name="current_folder" type="NautilusFileInfo*"/>
				</parameters>
			</method>
			<signal name="items-updated" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="NautilusMenuProvider*"/>
				</parameters>
			</signal>
			<vfunc name="get_background_items">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="provider" type="NautilusMenuProvider*"/>
					<parameter name="window" type="GtkWidget*"/>
					<parameter name="current_folder" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_file_items">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="provider" type="NautilusMenuProvider*"/>
					<parameter name="window" type="GtkWidget*"/>
					<parameter name="files" type="GList*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_toolbar_items">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="provider" type="NautilusMenuProvider*"/>
					<parameter name="window" type="GtkWidget*"/>
					<parameter name="current_folder" type="NautilusFileInfo*"/>
				</parameters>
			</vfunc>
		</interface>
		<interface name="NautilusPropertyPageProvider" type-name="NautilusPropertyPageProvider" get-type="nautilus_property_page_provider_get_type">
			<requires>
				<interface name="GObject"/>
			</requires>
			<method name="get_pages" symbol="nautilus_property_page_provider_get_pages">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="provider" type="NautilusPropertyPageProvider*"/>
					<parameter name="files" type="GList*"/>
				</parameters>
			</method>
			<vfunc name="get_pages">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="provider" type="NautilusPropertyPageProvider*"/>
					<parameter name="files" type="GList*"/>
				</parameters>
			</vfunc>
		</interface>
	</namespace>
</api>
