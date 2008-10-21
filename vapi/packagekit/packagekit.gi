<?xml version="1.0"?>
<api version="1.0">
	<namespace name="Pk">
		<function name="distro_upgrade_enum_from_text" symbol="pk_distro_upgrade_enum_from_text">
			<return-type type="PkDistroUpgradeEnum"/>
			<parameters>
				<parameter name="upgrade" type="gchar*"/>
			</parameters>
		</function>
		<function name="distro_upgrade_enum_to_text" symbol="pk_distro_upgrade_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="upgrade" type="PkDistroUpgradeEnum"/>
			</parameters>
		</function>
		<function name="enum_find_string" symbol="pk_enum_find_string">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="table" type="PkEnumMatch*"/>
				<parameter name="value" type="guint"/>
			</parameters>
		</function>
		<function name="enum_find_value" symbol="pk_enum_find_value">
			<return-type type="guint"/>
			<parameters>
				<parameter name="table" type="PkEnumMatch*"/>
				<parameter name="string" type="gchar*"/>
			</parameters>
		</function>
		<function name="error_enum_from_text" symbol="pk_error_enum_from_text">
			<return-type type="PkErrorCodeEnum"/>
			<parameters>
				<parameter name="code" type="gchar*"/>
			</parameters>
		</function>
		<function name="error_enum_to_text" symbol="pk_error_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="code" type="PkErrorCodeEnum"/>
			</parameters>
		</function>
		<function name="exit_enum_from_text" symbol="pk_exit_enum_from_text">
			<return-type type="PkExitEnum"/>
			<parameters>
				<parameter name="exit" type="gchar*"/>
			</parameters>
		</function>
		<function name="exit_enum_to_text" symbol="pk_exit_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="exit" type="PkExitEnum"/>
			</parameters>
		</function>
		<function name="filter_bitfield_from_text" symbol="pk_filter_bitfield_from_text">
			<return-type type="PkBitfield"/>
			<parameters>
				<parameter name="filters" type="gchar*"/>
			</parameters>
		</function>
		<function name="filter_bitfield_to_text" symbol="pk_filter_bitfield_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="filters" type="PkBitfield"/>
			</parameters>
		</function>
		<function name="filter_enum_from_text" symbol="pk_filter_enum_from_text">
			<return-type type="PkFilterEnum"/>
			<parameters>
				<parameter name="filter" type="gchar*"/>
			</parameters>
		</function>
		<function name="filter_enum_to_text" symbol="pk_filter_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="filter" type="PkFilterEnum"/>
			</parameters>
		</function>
		<function name="get_distro_id" symbol="pk_get_distro_id">
			<return-type type="gchar*"/>
		</function>
		<function name="group_bitfield_from_text" symbol="pk_group_bitfield_from_text">
			<return-type type="PkBitfield"/>
			<parameters>
				<parameter name="groups" type="gchar*"/>
			</parameters>
		</function>
		<function name="group_bitfield_to_text" symbol="pk_group_bitfield_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="groups" type="PkBitfield"/>
			</parameters>
		</function>
		<function name="group_enum_from_text" symbol="pk_group_enum_from_text">
			<return-type type="PkGroupEnum"/>
			<parameters>
				<parameter name="group" type="gchar*"/>
			</parameters>
		</function>
		<function name="group_enum_to_text" symbol="pk_group_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="group" type="PkGroupEnum"/>
			</parameters>
		</function>
		<function name="info_enum_from_text" symbol="pk_info_enum_from_text">
			<return-type type="PkInfoEnum"/>
			<parameters>
				<parameter name="info" type="gchar*"/>
			</parameters>
		</function>
		<function name="info_enum_to_text" symbol="pk_info_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="info" type="PkInfoEnum"/>
			</parameters>
		</function>
		<function name="iso8601_difference" symbol="pk_iso8601_difference">
			<return-type type="guint"/>
			<parameters>
				<parameter name="isodate" type="gchar*"/>
			</parameters>
		</function>
		<function name="iso8601_from_date" symbol="pk_iso8601_from_date">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="date" type="GDate*"/>
			</parameters>
		</function>
		<function name="iso8601_present" symbol="pk_iso8601_present">
			<return-type type="gchar*"/>
		</function>
		<function name="iso8601_to_date" symbol="pk_iso8601_to_date">
			<return-type type="GDate*"/>
			<parameters>
				<parameter name="iso_date" type="gchar*"/>
			</parameters>
		</function>
		<function name="license_enum_from_text" symbol="pk_license_enum_from_text">
			<return-type type="PkLicenseEnum"/>
			<parameters>
				<parameter name="license" type="gchar*"/>
			</parameters>
		</function>
		<function name="license_enum_to_text" symbol="pk_license_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="license" type="PkLicenseEnum"/>
			</parameters>
		</function>
		<function name="message_enum_from_text" symbol="pk_message_enum_from_text">
			<return-type type="PkMessageEnum"/>
			<parameters>
				<parameter name="message" type="gchar*"/>
			</parameters>
		</function>
		<function name="message_enum_to_text" symbol="pk_message_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="message" type="PkMessageEnum"/>
			</parameters>
		</function>
		<function name="network_enum_from_text" symbol="pk_network_enum_from_text">
			<return-type type="PkNetworkEnum"/>
			<parameters>
				<parameter name="network" type="gchar*"/>
			</parameters>
		</function>
		<function name="network_enum_to_text" symbol="pk_network_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="network" type="PkNetworkEnum"/>
			</parameters>
		</function>
		<function name="package_ids_check" symbol="pk_package_ids_check">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="package_ids" type="gchar**"/>
			</parameters>
		</function>
		<function name="package_ids_from_array" symbol="pk_package_ids_from_array">
			<return-type type="gchar**"/>
			<parameters>
				<parameter name="array" type="GPtrArray*"/>
			</parameters>
		</function>
		<function name="package_ids_from_id" symbol="pk_package_ids_from_id">
			<return-type type="gchar**"/>
			<parameters>
				<parameter name="package_id" type="gchar*"/>
			</parameters>
		</function>
		<function name="package_ids_from_text" symbol="pk_package_ids_from_text">
			<return-type type="gchar**"/>
			<parameters>
				<parameter name="package_id" type="gchar*"/>
			</parameters>
		</function>
		<function name="package_ids_from_va_list" symbol="pk_package_ids_from_va_list">
			<return-type type="gchar**"/>
			<parameters>
				<parameter name="package_id_first" type="gchar*"/>
				<parameter name="args" type="va_list*"/>
			</parameters>
		</function>
		<function name="package_ids_print" symbol="pk_package_ids_print">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="package_ids" type="gchar**"/>
			</parameters>
		</function>
		<function name="package_ids_size" symbol="pk_package_ids_size">
			<return-type type="guint"/>
			<parameters>
				<parameter name="package_ids" type="gchar**"/>
			</parameters>
		</function>
		<function name="package_ids_to_text" symbol="pk_package_ids_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="package_ids" type="gchar**"/>
			</parameters>
		</function>
		<function name="provides_enum_from_text" symbol="pk_provides_enum_from_text">
			<return-type type="PkProvidesEnum"/>
			<parameters>
				<parameter name="provides" type="gchar*"/>
			</parameters>
		</function>
		<function name="provides_enum_to_text" symbol="pk_provides_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="provides" type="PkProvidesEnum"/>
			</parameters>
		</function>
		<function name="ptr_array_to_strv" symbol="pk_ptr_array_to_strv">
			<return-type type="gchar**"/>
			<parameters>
				<parameter name="array" type="GPtrArray*"/>
			</parameters>
		</function>
		<function name="restart_enum_from_text" symbol="pk_restart_enum_from_text">
			<return-type type="PkRestartEnum"/>
			<parameters>
				<parameter name="restart" type="gchar*"/>
			</parameters>
		</function>
		<function name="restart_enum_to_text" symbol="pk_restart_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="restart" type="PkRestartEnum"/>
			</parameters>
		</function>
		<function name="role_bitfield_from_text" symbol="pk_role_bitfield_from_text">
			<return-type type="PkBitfield"/>
			<parameters>
				<parameter name="roles" type="gchar*"/>
			</parameters>
		</function>
		<function name="role_bitfield_to_text" symbol="pk_role_bitfield_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="roles" type="PkBitfield"/>
			</parameters>
		</function>
		<function name="role_enum_from_text" symbol="pk_role_enum_from_text">
			<return-type type="PkRoleEnum"/>
			<parameters>
				<parameter name="role" type="gchar*"/>
			</parameters>
		</function>
		<function name="role_enum_to_text" symbol="pk_role_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="role" type="PkRoleEnum"/>
			</parameters>
		</function>
		<function name="sig_type_enum_from_text" symbol="pk_sig_type_enum_from_text">
			<return-type type="PkSigTypeEnum"/>
			<parameters>
				<parameter name="sig_type" type="gchar*"/>
			</parameters>
		</function>
		<function name="sig_type_enum_to_text" symbol="pk_sig_type_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="sig_type" type="PkSigTypeEnum"/>
			</parameters>
		</function>
		<function name="status_enum_from_text" symbol="pk_status_enum_from_text">
			<return-type type="PkStatusEnum"/>
			<parameters>
				<parameter name="status" type="gchar*"/>
			</parameters>
		</function>
		<function name="status_enum_to_text" symbol="pk_status_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="status" type="PkStatusEnum"/>
			</parameters>
		</function>
		<function name="strsafe" symbol="pk_strsafe">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="text" type="gchar*"/>
			</parameters>
		</function>
		<function name="strv_to_ptr_array" symbol="pk_strv_to_ptr_array">
			<return-type type="GPtrArray*"/>
			<parameters>
				<parameter name="array" type="gchar**"/>
			</parameters>
		</function>
		<function name="strv_to_text" symbol="pk_strv_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="package_ids" type="gchar**"/>
				<parameter name="delimiter" type="gchar*"/>
			</parameters>
		</function>
		<function name="strvalidate" symbol="pk_strvalidate">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="text" type="gchar*"/>
			</parameters>
		</function>
		<function name="update_state_enum_from_text" symbol="pk_update_state_enum_from_text">
			<return-type type="PkUpdateStateEnum"/>
			<parameters>
				<parameter name="update_state" type="gchar*"/>
			</parameters>
		</function>
		<function name="update_state_enum_to_text" symbol="pk_update_state_enum_to_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="update_state" type="PkUpdateStateEnum"/>
			</parameters>
		</function>
		<function name="va_list_to_argv" symbol="pk_va_list_to_argv">
			<return-type type="gchar**"/>
			<parameters>
				<parameter name="string_first" type="gchar*"/>
				<parameter name="args" type="va_list*"/>
			</parameters>
		</function>
		<struct name="PkBitfield">
			<method name="contain_priority" symbol="pk_bitfield_contain_priority">
				<return-type type="gint"/>
				<parameters>
					<parameter name="values" type="PkBitfield"/>
					<parameter name="value" type="gint"/>
				</parameters>
			</method>
			<method name="from_enums" symbol="pk_bitfield_from_enums">
				<return-type type="PkBitfield"/>
				<parameters>
					<parameter name="value" type="gint"/>
				</parameters>
			</method>
		</struct>
		<struct name="PkDetailsObj">
			<method name="copy" symbol="pk_details_obj_copy">
				<return-type type="PkDetailsObj*"/>
				<parameters>
					<parameter name="obj" type="PkDetailsObj*"/>
				</parameters>
			</method>
			<method name="free" symbol="pk_details_obj_free">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="obj" type="PkDetailsObj*"/>
				</parameters>
			</method>
			<method name="new" symbol="pk_details_obj_new">
				<return-type type="PkDetailsObj*"/>
			</method>
			<method name="new_from_data" symbol="pk_details_obj_new_from_data">
				<return-type type="PkDetailsObj*"/>
				<parameters>
					<parameter name="id" type="PkPackageId*"/>
					<parameter name="license" type="gchar*"/>
					<parameter name="group" type="PkGroupEnum"/>
					<parameter name="description" type="gchar*"/>
					<parameter name="url" type="gchar*"/>
					<parameter name="size" type="guint64"/>
				</parameters>
			</method>
			<field name="id" type="PkPackageId*"/>
			<field name="license" type="gchar*"/>
			<field name="group" type="PkGroupEnum"/>
			<field name="description" type="gchar*"/>
			<field name="url" type="gchar*"/>
			<field name="size" type="guint64"/>
		</struct>
		<struct name="PkDistroUpgradeObj">
			<method name="copy" symbol="pk_distro_upgrade_obj_copy">
				<return-type type="PkDistroUpgradeObj*"/>
				<parameters>
					<parameter name="obj" type="PkDistroUpgradeObj*"/>
				</parameters>
			</method>
			<method name="free" symbol="pk_distro_upgrade_obj_free">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="obj" type="PkDistroUpgradeObj*"/>
				</parameters>
			</method>
			<method name="new" symbol="pk_distro_upgrade_obj_new">
				<return-type type="PkDistroUpgradeObj*"/>
			</method>
			<method name="new_from_data" symbol="pk_distro_upgrade_obj_new_from_data">
				<return-type type="PkDistroUpgradeObj*"/>
				<parameters>
					<parameter name="state" type="PkUpdateStateEnum"/>
					<parameter name="name" type="gchar*"/>
					<parameter name="summary" type="gchar*"/>
				</parameters>
			</method>
			<field name="state" type="PkUpdateStateEnum"/>
			<field name="name" type="gchar*"/>
			<field name="summary" type="gchar*"/>
		</struct>
		<struct name="PkEnumMatch">
			<field name="value" type="guint"/>
			<field name="string" type="gchar*"/>
		</struct>
		<struct name="PkPackageId">
			<method name="build" symbol="pk_package_id_build">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="name" type="gchar*"/>
					<parameter name="version" type="gchar*"/>
					<parameter name="arch" type="gchar*"/>
					<parameter name="data" type="gchar*"/>
				</parameters>
			</method>
			<method name="check" symbol="pk_package_id_check">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="package_id" type="gchar*"/>
				</parameters>
			</method>
			<method name="copy" symbol="pk_package_id_copy">
				<return-type type="PkPackageId*"/>
				<parameters>
					<parameter name="id" type="PkPackageId*"/>
				</parameters>
			</method>
			<method name="equal" symbol="pk_package_id_equal">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="id1" type="PkPackageId*"/>
					<parameter name="id2" type="PkPackageId*"/>
				</parameters>
			</method>
			<method name="equal_strings" symbol="pk_package_id_equal_strings">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="pid1" type="gchar*"/>
					<parameter name="pid2" type="gchar*"/>
				</parameters>
			</method>
			<method name="free" symbol="pk_package_id_free">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="id" type="PkPackageId*"/>
				</parameters>
			</method>
			<method name="new" symbol="pk_package_id_new">
				<return-type type="PkPackageId*"/>
			</method>
			<method name="new_from_list" symbol="pk_package_id_new_from_list">
				<return-type type="PkPackageId*"/>
				<parameters>
					<parameter name="name" type="gchar*"/>
					<parameter name="version" type="gchar*"/>
					<parameter name="arch" type="gchar*"/>
					<parameter name="data" type="gchar*"/>
				</parameters>
			</method>
			<method name="new_from_string" symbol="pk_package_id_new_from_string">
				<return-type type="PkPackageId*"/>
				<parameters>
					<parameter name="package_id" type="gchar*"/>
				</parameters>
			</method>
			<method name="to_string" symbol="pk_package_id_to_string">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="id" type="PkPackageId*"/>
				</parameters>
			</method>
			<field name="name" type="gchar*"/>
			<field name="version" type="gchar*"/>
			<field name="arch" type="gchar*"/>
			<field name="data" type="gchar*"/>
		</struct>
		<struct name="PkPackageObj">
			<method name="copy" symbol="pk_package_obj_copy">
				<return-type type="PkPackageObj*"/>
				<parameters>
					<parameter name="obj" type="PkPackageObj*"/>
				</parameters>
			</method>
			<method name="equal" symbol="pk_package_obj_equal">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="obj1" type="PkPackageObj*"/>
					<parameter name="obj2" type="PkPackageObj*"/>
				</parameters>
			</method>
			<method name="free" symbol="pk_package_obj_free">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="obj" type="PkPackageObj*"/>
				</parameters>
			</method>
			<method name="from_string" symbol="pk_package_obj_from_string">
				<return-type type="PkPackageObj*"/>
				<parameters>
					<parameter name="text" type="gchar*"/>
				</parameters>
			</method>
			<method name="new" symbol="pk_package_obj_new">
				<return-type type="PkPackageObj*"/>
				<parameters>
					<parameter name="info" type="PkInfoEnum"/>
					<parameter name="id" type="PkPackageId*"/>
					<parameter name="summary" type="gchar*"/>
				</parameters>
			</method>
			<method name="to_string" symbol="pk_package_obj_to_string">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="obj" type="PkPackageObj*"/>
				</parameters>
			</method>
			<field name="info" type="PkInfoEnum"/>
			<field name="id" type="PkPackageId*"/>
			<field name="summary" type="gchar*"/>
		</struct>
		<struct name="PkTaskListItem">
			<field name="tid" type="gchar*"/>
			<field name="status" type="PkStatusEnum"/>
			<field name="role" type="PkRoleEnum"/>
			<field name="text" type="gchar*"/>
			<field name="monitor" type="PkClient*"/>
			<field name="valid" type="gboolean"/>
		</struct>
		<struct name="PkUpdateDetailObj">
			<method name="copy" symbol="pk_update_detail_obj_copy">
				<return-type type="PkUpdateDetailObj*"/>
				<parameters>
					<parameter name="obj" type="PkUpdateDetailObj*"/>
				</parameters>
			</method>
			<method name="free" symbol="pk_update_detail_obj_free">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="obj" type="PkUpdateDetailObj*"/>
				</parameters>
			</method>
			<method name="new" symbol="pk_update_detail_obj_new">
				<return-type type="PkUpdateDetailObj*"/>
			</method>
			<method name="new_from_data" symbol="pk_update_detail_obj_new_from_data">
				<return-type type="PkUpdateDetailObj*"/>
				<parameters>
					<parameter name="id" type="PkPackageId*"/>
					<parameter name="updates" type="gchar*"/>
					<parameter name="obsoletes" type="gchar*"/>
					<parameter name="vendor_url" type="gchar*"/>
					<parameter name="bugzilla_url" type="gchar*"/>
					<parameter name="cve_url" type="gchar*"/>
					<parameter name="restart" type="PkRestartEnum"/>
					<parameter name="update_text" type="gchar*"/>
					<parameter name="changelog" type="gchar*"/>
					<parameter name="state" type="PkUpdateStateEnum"/>
					<parameter name="issued" type="GDate*"/>
					<parameter name="updated" type="GDate*"/>
				</parameters>
			</method>
			<field name="id" type="PkPackageId*"/>
			<field name="updates" type="gchar*"/>
			<field name="obsoletes" type="gchar*"/>
			<field name="vendor_url" type="gchar*"/>
			<field name="bugzilla_url" type="gchar*"/>
			<field name="cve_url" type="gchar*"/>
			<field name="restart" type="PkRestartEnum"/>
			<field name="update_text" type="gchar*"/>
			<field name="changelog" type="gchar*"/>
			<field name="state" type="PkUpdateStateEnum"/>
			<field name="issued" type="GDate*"/>
			<field name="updated" type="GDate*"/>
		</struct>
		<enum name="PkCatalogProgress">
			<member name="PK_CATALOG_PROGRESS_PACKAGES" value="0"/>
			<member name="PK_CATALOG_PROGRESS_FILES" value="1"/>
			<member name="PK_CATALOG_PROGRESS_PROVIDES" value="2"/>
			<member name="PK_CATALOG_PROGRESS_LAST" value="3"/>
		</enum>
		<enum name="PkClientError" type-name="PkClientError" get-type="pk_client_error_get_type">
			<member name="PK_CLIENT_ERROR_FAILED" value="0"/>
			<member name="PK_CLIENT_ERROR_FAILED_AUTH" value="1"/>
			<member name="PK_CLIENT_ERROR_NO_TID" value="2"/>
			<member name="PK_CLIENT_ERROR_ALREADY_TID" value="3"/>
			<member name="PK_CLIENT_ERROR_ROLE_UNKNOWN" value="4"/>
			<member name="PK_CLIENT_ERROR_CANNOT_START_DAEMON" value="5"/>
			<member name="PK_CLIENT_ERROR_INVALID_PACKAGEID" value="6"/>
		</enum>
		<enum name="PkControlError">
			<member name="PK_CONTROL_ERROR_FAILED" value="0"/>
			<member name="PK_CONTROL_ERROR_CANNOT_START_DAEMON" value="1"/>
		</enum>
		<enum name="PkDistroUpgradeEnum">
			<member name="PK_DISTRO_UPGRADE_ENUM_STABLE" value="0"/>
			<member name="PK_DISTRO_UPGRADE_ENUM_UNSTABLE" value="1"/>
			<member name="PK_DISTRO_UPGRADE_ENUM_UNKNOWN" value="2"/>
		</enum>
		<enum name="PkErrorCodeEnum">
			<member name="PK_ERROR_ENUM_OOM" value="0"/>
			<member name="PK_ERROR_ENUM_NO_NETWORK" value="1"/>
			<member name="PK_ERROR_ENUM_NOT_SUPPORTED" value="2"/>
			<member name="PK_ERROR_ENUM_INTERNAL_ERROR" value="3"/>
			<member name="PK_ERROR_ENUM_GPG_FAILURE" value="4"/>
			<member name="PK_ERROR_ENUM_PACKAGE_ID_INVALID" value="5"/>
			<member name="PK_ERROR_ENUM_PACKAGE_NOT_INSTALLED" value="6"/>
			<member name="PK_ERROR_ENUM_PACKAGE_NOT_FOUND" value="7"/>
			<member name="PK_ERROR_ENUM_PACKAGE_ALREADY_INSTALLED" value="8"/>
			<member name="PK_ERROR_ENUM_PACKAGE_DOWNLOAD_FAILED" value="9"/>
			<member name="PK_ERROR_ENUM_GROUP_NOT_FOUND" value="10"/>
			<member name="PK_ERROR_ENUM_GROUP_LIST_INVALID" value="11"/>
			<member name="PK_ERROR_ENUM_DEP_RESOLUTION_FAILED" value="12"/>
			<member name="PK_ERROR_ENUM_FILTER_INVALID" value="13"/>
			<member name="PK_ERROR_ENUM_CREATE_THREAD_FAILED" value="14"/>
			<member name="PK_ERROR_ENUM_TRANSACTION_ERROR" value="15"/>
			<member name="PK_ERROR_ENUM_TRANSACTION_CANCELLED" value="16"/>
			<member name="PK_ERROR_ENUM_NO_CACHE" value="17"/>
			<member name="PK_ERROR_ENUM_REPO_NOT_FOUND" value="18"/>
			<member name="PK_ERROR_ENUM_CANNOT_REMOVE_SYSTEM_PACKAGE" value="19"/>
			<member name="PK_ERROR_ENUM_PROCESS_KILL" value="20"/>
			<member name="PK_ERROR_ENUM_FAILED_INITIALIZATION" value="21"/>
			<member name="PK_ERROR_ENUM_FAILED_FINALISE" value="22"/>
			<member name="PK_ERROR_ENUM_FAILED_CONFIG_PARSING" value="23"/>
			<member name="PK_ERROR_ENUM_CANNOT_CANCEL" value="24"/>
			<member name="PK_ERROR_ENUM_CANNOT_GET_LOCK" value="25"/>
			<member name="PK_ERROR_ENUM_NO_PACKAGES_TO_UPDATE" value="26"/>
			<member name="PK_ERROR_ENUM_CANNOT_WRITE_REPO_CONFIG" value="27"/>
			<member name="PK_ERROR_ENUM_LOCAL_INSTALL_FAILED" value="28"/>
			<member name="PK_ERROR_ENUM_BAD_GPG_SIGNATURE" value="29"/>
			<member name="PK_ERROR_ENUM_MISSING_GPG_SIGNATURE" value="30"/>
			<member name="PK_ERROR_ENUM_CANNOT_INSTALL_SOURCE_PACKAGE" value="31"/>
			<member name="PK_ERROR_ENUM_REPO_CONFIGURATION_ERROR" value="32"/>
			<member name="PK_ERROR_ENUM_NO_LICENSE_AGREEMENT" value="33"/>
			<member name="PK_ERROR_ENUM_FILE_CONFLICTS" value="34"/>
			<member name="PK_ERROR_ENUM_PACKAGE_CONFLICTS" value="35"/>
			<member name="PK_ERROR_ENUM_REPO_NOT_AVAILABLE" value="36"/>
			<member name="PK_ERROR_ENUM_INVALID_PACKAGE_FILE" value="37"/>
			<member name="PK_ERROR_ENUM_PACKAGE_INSTALL_BLOCKED" value="38"/>
			<member name="PK_ERROR_ENUM_PACKAGE_CORRUPT" value="39"/>
			<member name="PK_ERROR_ENUM_ALL_PACKAGES_ALREADY_INSTALLED" value="40"/>
			<member name="PK_ERROR_ENUM_FILE_NOT_FOUND" value="41"/>
			<member name="PK_ERROR_ENUM_NO_MORE_MIRRORS_TO_TRY" value="42"/>
			<member name="PK_ERROR_ENUM_UNKNOWN" value="43"/>
		</enum>
		<enum name="PkExitEnum">
			<member name="PK_EXIT_ENUM_SUCCESS" value="0"/>
			<member name="PK_EXIT_ENUM_FAILED" value="1"/>
			<member name="PK_EXIT_ENUM_CANCELLED" value="2"/>
			<member name="PK_EXIT_ENUM_KEY_REQUIRED" value="3"/>
			<member name="PK_EXIT_ENUM_EULA_REQUIRED" value="4"/>
			<member name="PK_EXIT_ENUM_KILLED" value="5"/>
			<member name="PK_EXIT_ENUM_UNKNOWN" value="6"/>
		</enum>
		<enum name="PkExtraAccess">
			<member name="PK_EXTRA_ACCESS_READ_ONLY" value="0"/>
			<member name="PK_EXTRA_ACCESS_WRITE_ONLY" value="1"/>
			<member name="PK_EXTRA_ACCESS_READ_WRITE" value="2"/>
		</enum>
		<enum name="PkFilterEnum">
			<member name="PK_FILTER_ENUM_NONE" value="0"/>
			<member name="PK_FILTER_ENUM_INSTALLED" value="1"/>
			<member name="PK_FILTER_ENUM_NOT_INSTALLED" value="2"/>
			<member name="PK_FILTER_ENUM_DEVELOPMENT" value="3"/>
			<member name="PK_FILTER_ENUM_NOT_DEVELOPMENT" value="4"/>
			<member name="PK_FILTER_ENUM_GUI" value="5"/>
			<member name="PK_FILTER_ENUM_NOT_GUI" value="6"/>
			<member name="PK_FILTER_ENUM_FREE" value="7"/>
			<member name="PK_FILTER_ENUM_NOT_FREE" value="8"/>
			<member name="PK_FILTER_ENUM_VISIBLE" value="9"/>
			<member name="PK_FILTER_ENUM_NOT_VISIBLE" value="10"/>
			<member name="PK_FILTER_ENUM_SUPPORTED" value="11"/>
			<member name="PK_FILTER_ENUM_NOT_SUPPORTED" value="12"/>
			<member name="PK_FILTER_ENUM_BASENAME" value="13"/>
			<member name="PK_FILTER_ENUM_NOT_BASENAME" value="14"/>
			<member name="PK_FILTER_ENUM_NEWEST" value="15"/>
			<member name="PK_FILTER_ENUM_NOT_NEWEST" value="16"/>
			<member name="PK_FILTER_ENUM_ARCH" value="17"/>
			<member name="PK_FILTER_ENUM_NOT_ARCH" value="18"/>
			<member name="PK_FILTER_ENUM_SOURCE" value="19"/>
			<member name="PK_FILTER_ENUM_NOT_SOURCE" value="20"/>
			<member name="PK_FILTER_ENUM_COLLECTIONS" value="21"/>
			<member name="PK_FILTER_ENUM_NOT_COLLECTIONS" value="22"/>
			<member name="PK_FILTER_ENUM_UNKNOWN" value="23"/>
		</enum>
		<enum name="PkGroupEnum">
			<member name="PK_GROUP_ENUM_ACCESSIBILITY" value="0"/>
			<member name="PK_GROUP_ENUM_ACCESSORIES" value="1"/>
			<member name="PK_GROUP_ENUM_ADMIN_TOOLS" value="2"/>
			<member name="PK_GROUP_ENUM_COMMUNICATION" value="3"/>
			<member name="PK_GROUP_ENUM_DESKTOP_GNOME" value="4"/>
			<member name="PK_GROUP_ENUM_DESKTOP_KDE" value="5"/>
			<member name="PK_GROUP_ENUM_DESKTOP_OTHER" value="6"/>
			<member name="PK_GROUP_ENUM_DESKTOP_XFCE" value="7"/>
			<member name="PK_GROUP_ENUM_EDUCATION" value="8"/>
			<member name="PK_GROUP_ENUM_FONTS" value="9"/>
			<member name="PK_GROUP_ENUM_GAMES" value="10"/>
			<member name="PK_GROUP_ENUM_GRAPHICS" value="11"/>
			<member name="PK_GROUP_ENUM_INTERNET" value="12"/>
			<member name="PK_GROUP_ENUM_LEGACY" value="13"/>
			<member name="PK_GROUP_ENUM_LOCALIZATION" value="14"/>
			<member name="PK_GROUP_ENUM_MAPS" value="15"/>
			<member name="PK_GROUP_ENUM_MULTIMEDIA" value="16"/>
			<member name="PK_GROUP_ENUM_NETWORK" value="17"/>
			<member name="PK_GROUP_ENUM_OFFICE" value="18"/>
			<member name="PK_GROUP_ENUM_OTHER" value="19"/>
			<member name="PK_GROUP_ENUM_POWER_MANAGEMENT" value="20"/>
			<member name="PK_GROUP_ENUM_PROGRAMMING" value="21"/>
			<member name="PK_GROUP_ENUM_PUBLISHING" value="22"/>
			<member name="PK_GROUP_ENUM_REPOS" value="23"/>
			<member name="PK_GROUP_ENUM_SECURITY" value="24"/>
			<member name="PK_GROUP_ENUM_SERVERS" value="25"/>
			<member name="PK_GROUP_ENUM_SYSTEM" value="26"/>
			<member name="PK_GROUP_ENUM_VIRTUALIZATION" value="27"/>
			<member name="PK_GROUP_ENUM_SCIENCE" value="28"/>
			<member name="PK_GROUP_ENUM_DOCUMENTATION" value="29"/>
			<member name="PK_GROUP_ENUM_ELECTRONICS" value="30"/>
			<member name="PK_GROUP_ENUM_COLLECTIONS" value="31"/>
			<member name="PK_GROUP_ENUM_VENDOR" value="32"/>
			<member name="PK_GROUP_ENUM_UNKNOWN" value="33"/>
		</enum>
		<enum name="PkInfoEnum">
			<member name="PK_INFO_ENUM_INSTALLED" value="0"/>
			<member name="PK_INFO_ENUM_AVAILABLE" value="1"/>
			<member name="PK_INFO_ENUM_LOW" value="2"/>
			<member name="PK_INFO_ENUM_ENHANCEMENT" value="3"/>
			<member name="PK_INFO_ENUM_NORMAL" value="4"/>
			<member name="PK_INFO_ENUM_BUGFIX" value="5"/>
			<member name="PK_INFO_ENUM_IMPORTANT" value="6"/>
			<member name="PK_INFO_ENUM_SECURITY" value="7"/>
			<member name="PK_INFO_ENUM_BLOCKED" value="8"/>
			<member name="PK_INFO_ENUM_DOWNLOADING" value="9"/>
			<member name="PK_INFO_ENUM_UPDATING" value="10"/>
			<member name="PK_INFO_ENUM_INSTALLING" value="11"/>
			<member name="PK_INFO_ENUM_REMOVING" value="12"/>
			<member name="PK_INFO_ENUM_CLEANUP" value="13"/>
			<member name="PK_INFO_ENUM_OBSOLETING" value="14"/>
			<member name="PK_INFO_ENUM_COLLECTION_INSTALLED" value="15"/>
			<member name="PK_INFO_ENUM_COLLECTION_AVAILABLE" value="16"/>
			<member name="PK_INFO_ENUM_UNKNOWN" value="17"/>
		</enum>
		<enum name="PkLicenseEnum">
			<member name="PK_LICENSE_ENUM_GLIDE" value="0"/>
			<member name="PK_LICENSE_ENUM_AFL" value="1"/>
			<member name="PK_LICENSE_ENUM_AMPAS_BSD" value="2"/>
			<member name="PK_LICENSE_ENUM_AMAZON_DSL" value="3"/>
			<member name="PK_LICENSE_ENUM_ADOBE" value="4"/>
			<member name="PK_LICENSE_ENUM_AGPLV1" value="5"/>
			<member name="PK_LICENSE_ENUM_AGPLV3" value="6"/>
			<member name="PK_LICENSE_ENUM_ASL_1_DOT_0" value="7"/>
			<member name="PK_LICENSE_ENUM_ASL_1_DOT_1" value="8"/>
			<member name="PK_LICENSE_ENUM_ASL_2_DOT_0" value="9"/>
			<member name="PK_LICENSE_ENUM_APSL_2_DOT_0" value="10"/>
			<member name="PK_LICENSE_ENUM_ARTISTIC_CLARIFIED" value="11"/>
			<member name="PK_LICENSE_ENUM_ARTISTIC_2_DOT_0" value="12"/>
			<member name="PK_LICENSE_ENUM_ARL" value="13"/>
			<member name="PK_LICENSE_ENUM_BITTORRENT" value="14"/>
			<member name="PK_LICENSE_ENUM_BOOST" value="15"/>
			<member name="PK_LICENSE_ENUM_BSD_WITH_ADVERTISING" value="16"/>
			<member name="PK_LICENSE_ENUM_BSD" value="17"/>
			<member name="PK_LICENSE_ENUM_CECILL" value="18"/>
			<member name="PK_LICENSE_ENUM_CDDL" value="19"/>
			<member name="PK_LICENSE_ENUM_CPL" value="20"/>
			<member name="PK_LICENSE_ENUM_CONDOR" value="21"/>
			<member name="PK_LICENSE_ENUM_COPYRIGHT_ONLY" value="22"/>
			<member name="PK_LICENSE_ENUM_CRYPTIX" value="23"/>
			<member name="PK_LICENSE_ENUM_CRYSTAL_STACKER" value="24"/>
			<member name="PK_LICENSE_ENUM_DOC" value="25"/>
			<member name="PK_LICENSE_ENUM_WTFPL" value="26"/>
			<member name="PK_LICENSE_ENUM_EPL" value="27"/>
			<member name="PK_LICENSE_ENUM_ECOS" value="28"/>
			<member name="PK_LICENSE_ENUM_EFL_2_DOT_0" value="29"/>
			<member name="PK_LICENSE_ENUM_EU_DATAGRID" value="30"/>
			<member name="PK_LICENSE_ENUM_LGPLV2_WITH_EXCEPTIONS" value="31"/>
			<member name="PK_LICENSE_ENUM_FTL" value="32"/>
			<member name="PK_LICENSE_ENUM_GIFTWARE" value="33"/>
			<member name="PK_LICENSE_ENUM_GPLV2" value="34"/>
			<member name="PK_LICENSE_ENUM_GPLV2_WITH_EXCEPTIONS" value="35"/>
			<member name="PK_LICENSE_ENUM_GPLV2_PLUS_WITH_EXCEPTIONS" value="36"/>
			<member name="PK_LICENSE_ENUM_GPLV3" value="37"/>
			<member name="PK_LICENSE_ENUM_GPLV3_WITH_EXCEPTIONS" value="38"/>
			<member name="PK_LICENSE_ENUM_GPLV3_PLUS_WITH_EXCEPTIONS" value="39"/>
			<member name="PK_LICENSE_ENUM_LGPLV2" value="40"/>
			<member name="PK_LICENSE_ENUM_LGPLV3" value="41"/>
			<member name="PK_LICENSE_ENUM_GNUPLOT" value="42"/>
			<member name="PK_LICENSE_ENUM_IBM" value="43"/>
			<member name="PK_LICENSE_ENUM_IMATIX" value="44"/>
			<member name="PK_LICENSE_ENUM_IMAGEMAGICK" value="45"/>
			<member name="PK_LICENSE_ENUM_IMLIB2" value="46"/>
			<member name="PK_LICENSE_ENUM_IJG" value="47"/>
			<member name="PK_LICENSE_ENUM_INTEL_ACPI" value="48"/>
			<member name="PK_LICENSE_ENUM_INTERBASE" value="49"/>
			<member name="PK_LICENSE_ENUM_ISC" value="50"/>
			<member name="PK_LICENSE_ENUM_JABBER" value="51"/>
			<member name="PK_LICENSE_ENUM_JASPER" value="52"/>
			<member name="PK_LICENSE_ENUM_LPPL" value="53"/>
			<member name="PK_LICENSE_ENUM_LIBTIFF" value="54"/>
			<member name="PK_LICENSE_ENUM_LPL" value="55"/>
			<member name="PK_LICENSE_ENUM_MECAB_IPADIC" value="56"/>
			<member name="PK_LICENSE_ENUM_MIT" value="57"/>
			<member name="PK_LICENSE_ENUM_MIT_WITH_ADVERTISING" value="58"/>
			<member name="PK_LICENSE_ENUM_MPLV1_DOT_0" value="59"/>
			<member name="PK_LICENSE_ENUM_MPLV1_DOT_1" value="60"/>
			<member name="PK_LICENSE_ENUM_NCSA" value="61"/>
			<member name="PK_LICENSE_ENUM_NGPL" value="62"/>
			<member name="PK_LICENSE_ENUM_NOSL" value="63"/>
			<member name="PK_LICENSE_ENUM_NETCDF" value="64"/>
			<member name="PK_LICENSE_ENUM_NETSCAPE" value="65"/>
			<member name="PK_LICENSE_ENUM_NOKIA" value="66"/>
			<member name="PK_LICENSE_ENUM_OPENLDAP" value="67"/>
			<member name="PK_LICENSE_ENUM_OPENPBS" value="68"/>
			<member name="PK_LICENSE_ENUM_OSL_1_DOT_0" value="69"/>
			<member name="PK_LICENSE_ENUM_OSL_1_DOT_1" value="70"/>
			<member name="PK_LICENSE_ENUM_OSL_2_DOT_0" value="71"/>
			<member name="PK_LICENSE_ENUM_OSL_3_DOT_0" value="72"/>
			<member name="PK_LICENSE_ENUM_OPENSSL" value="73"/>
			<member name="PK_LICENSE_ENUM_OREILLY" value="74"/>
			<member name="PK_LICENSE_ENUM_PHORUM" value="75"/>
			<member name="PK_LICENSE_ENUM_PHP" value="76"/>
			<member name="PK_LICENSE_ENUM_PUBLIC_DOMAIN" value="77"/>
			<member name="PK_LICENSE_ENUM_PYTHON" value="78"/>
			<member name="PK_LICENSE_ENUM_QPL" value="79"/>
			<member name="PK_LICENSE_ENUM_RPSL" value="80"/>
			<member name="PK_LICENSE_ENUM_RUBY" value="81"/>
			<member name="PK_LICENSE_ENUM_SENDMAIL" value="82"/>
			<member name="PK_LICENSE_ENUM_SLEEPYCAT" value="83"/>
			<member name="PK_LICENSE_ENUM_SLIB" value="84"/>
			<member name="PK_LICENSE_ENUM_SISSL" value="85"/>
			<member name="PK_LICENSE_ENUM_SPL" value="86"/>
			<member name="PK_LICENSE_ENUM_TCL" value="87"/>
			<member name="PK_LICENSE_ENUM_UCD" value="88"/>
			<member name="PK_LICENSE_ENUM_VIM" value="89"/>
			<member name="PK_LICENSE_ENUM_VNLSL" value="90"/>
			<member name="PK_LICENSE_ENUM_VSL" value="91"/>
			<member name="PK_LICENSE_ENUM_W3C" value="92"/>
			<member name="PK_LICENSE_ENUM_WXWIDGETS" value="93"/>
			<member name="PK_LICENSE_ENUM_XINETD" value="94"/>
			<member name="PK_LICENSE_ENUM_ZEND" value="95"/>
			<member name="PK_LICENSE_ENUM_ZPLV1_DOT_0" value="96"/>
			<member name="PK_LICENSE_ENUM_ZPLV2_DOT_0" value="97"/>
			<member name="PK_LICENSE_ENUM_ZPLV2_DOT_1" value="98"/>
			<member name="PK_LICENSE_ENUM_ZLIB" value="99"/>
			<member name="PK_LICENSE_ENUM_ZLIB_WITH_ACK" value="100"/>
			<member name="PK_LICENSE_ENUM_CDL" value="101"/>
			<member name="PK_LICENSE_ENUM_FBSDDL" value="102"/>
			<member name="PK_LICENSE_ENUM_GFDL" value="103"/>
			<member name="PK_LICENSE_ENUM_IEEE" value="104"/>
			<member name="PK_LICENSE_ENUM_OFSFDL" value="105"/>
			<member name="PK_LICENSE_ENUM_OPEN_PUBLICATION" value="106"/>
			<member name="PK_LICENSE_ENUM_CC_BY" value="107"/>
			<member name="PK_LICENSE_ENUM_CC_BY_SA" value="108"/>
			<member name="PK_LICENSE_ENUM_CC_BY_ND" value="109"/>
			<member name="PK_LICENSE_ENUM_DSL" value="110"/>
			<member name="PK_LICENSE_ENUM_FREE_ART" value="111"/>
			<member name="PK_LICENSE_ENUM_OFL" value="112"/>
			<member name="PK_LICENSE_ENUM_UTOPIA" value="113"/>
			<member name="PK_LICENSE_ENUM_ARPHIC" value="114"/>
			<member name="PK_LICENSE_ENUM_BAEKMUK" value="115"/>
			<member name="PK_LICENSE_ENUM_BITSTREAM_VERA" value="116"/>
			<member name="PK_LICENSE_ENUM_LUCIDA" value="117"/>
			<member name="PK_LICENSE_ENUM_MPLUS" value="118"/>
			<member name="PK_LICENSE_ENUM_STIX" value="119"/>
			<member name="PK_LICENSE_ENUM_XANO" value="120"/>
			<member name="PK_LICENSE_ENUM_VOSTROM" value="121"/>
			<member name="PK_LICENSE_ENUM_XEROX" value="122"/>
			<member name="PK_LICENSE_ENUM_RICEBSD" value="123"/>
			<member name="PK_LICENSE_ENUM_QHULL" value="124"/>
			<member name="PK_LICENSE_ENUM_UNKNOWN" value="125"/>
		</enum>
		<enum name="PkMessageEnum">
			<member name="PK_MESSAGE_ENUM_BROKEN_MIRROR" value="0"/>
			<member name="PK_MESSAGE_ENUM_CONNECTION_REFUSED" value="1"/>
			<member name="PK_MESSAGE_ENUM_PARAMETER_INVALID" value="2"/>
			<member name="PK_MESSAGE_ENUM_PRIORITY_INVALID" value="3"/>
			<member name="PK_MESSAGE_ENUM_BACKEND_ERROR" value="4"/>
			<member name="PK_MESSAGE_ENUM_DAEMON_ERROR" value="5"/>
			<member name="PK_MESSAGE_ENUM_CACHE_BEING_REBUILT" value="6"/>
			<member name="PK_MESSAGE_ENUM_UNTRUSTED_PACKAGE" value="7"/>
			<member name="PK_MESSAGE_ENUM_NEWER_PACKAGE_EXISTS" value="8"/>
			<member name="PK_MESSAGE_ENUM_COULD_NOT_FIND_PACKAGE" value="9"/>
			<member name="PK_MESSAGE_ENUM_CONFIG_FILES_CHANGED" value="10"/>
			<member name="PK_MESSAGE_ENUM_PACKAGE_ALREADY_INSTALLED" value="11"/>
			<member name="PK_MESSAGE_ENUM_UNKNOWN" value="12"/>
		</enum>
		<enum name="PkNetworkEnum">
			<member name="PK_NETWORK_ENUM_OFFLINE" value="0"/>
			<member name="PK_NETWORK_ENUM_ONLINE" value="1"/>
			<member name="PK_NETWORK_ENUM_SLOW" value="2"/>
			<member name="PK_NETWORK_ENUM_FAST" value="3"/>
			<member name="PK_NETWORK_ENUM_UNKNOWN" value="4"/>
		</enum>
		<enum name="PkProvidesEnum">
			<member name="PK_PROVIDES_ENUM_ANY" value="0"/>
			<member name="PK_PROVIDES_ENUM_MODALIAS" value="1"/>
			<member name="PK_PROVIDES_ENUM_CODEC" value="2"/>
			<member name="PK_PROVIDES_ENUM_MIMETYPE" value="3"/>
			<member name="PK_PROVIDES_ENUM_FONT" value="4"/>
			<member name="PK_PROVIDES_ENUM_HARDWARE_DRIVER" value="5"/>
			<member name="PK_PROVIDES_ENUM_UNKNOWN" value="6"/>
		</enum>
		<enum name="PkRestartEnum">
			<member name="PK_RESTART_ENUM_NONE" value="0"/>
			<member name="PK_RESTART_ENUM_APPLICATION" value="1"/>
			<member name="PK_RESTART_ENUM_SESSION" value="2"/>
			<member name="PK_RESTART_ENUM_SYSTEM" value="3"/>
			<member name="PK_RESTART_ENUM_UNKNOWN" value="4"/>
		</enum>
		<enum name="PkRoleEnum">
			<member name="PK_ROLE_ENUM_CANCEL" value="0"/>
			<member name="PK_ROLE_ENUM_GET_DEPENDS" value="1"/>
			<member name="PK_ROLE_ENUM_GET_DETAILS" value="2"/>
			<member name="PK_ROLE_ENUM_GET_FILES" value="3"/>
			<member name="PK_ROLE_ENUM_GET_PACKAGES" value="4"/>
			<member name="PK_ROLE_ENUM_GET_REPO_LIST" value="5"/>
			<member name="PK_ROLE_ENUM_GET_REQUIRES" value="6"/>
			<member name="PK_ROLE_ENUM_GET_UPDATE_DETAIL" value="7"/>
			<member name="PK_ROLE_ENUM_GET_UPDATES" value="8"/>
			<member name="PK_ROLE_ENUM_INSTALL_FILES" value="9"/>
			<member name="PK_ROLE_ENUM_INSTALL_PACKAGES" value="10"/>
			<member name="PK_ROLE_ENUM_INSTALL_SIGNATURE" value="11"/>
			<member name="PK_ROLE_ENUM_REFRESH_CACHE" value="12"/>
			<member name="PK_ROLE_ENUM_REMOVE_PACKAGES" value="13"/>
			<member name="PK_ROLE_ENUM_REPO_ENABLE" value="14"/>
			<member name="PK_ROLE_ENUM_REPO_SET_DATA" value="15"/>
			<member name="PK_ROLE_ENUM_RESOLVE" value="16"/>
			<member name="PK_ROLE_ENUM_ROLLBACK" value="17"/>
			<member name="PK_ROLE_ENUM_SEARCH_DETAILS" value="18"/>
			<member name="PK_ROLE_ENUM_SEARCH_FILE" value="19"/>
			<member name="PK_ROLE_ENUM_SEARCH_GROUP" value="20"/>
			<member name="PK_ROLE_ENUM_SEARCH_NAME" value="21"/>
			<member name="PK_ROLE_ENUM_SERVICE_PACK" value="22"/>
			<member name="PK_ROLE_ENUM_UPDATE_PACKAGES" value="23"/>
			<member name="PK_ROLE_ENUM_UPDATE_SYSTEM" value="24"/>
			<member name="PK_ROLE_ENUM_WHAT_PROVIDES" value="25"/>
			<member name="PK_ROLE_ENUM_ACCEPT_EULA" value="26"/>
			<member name="PK_ROLE_ENUM_DOWNLOAD_PACKAGES" value="27"/>
			<member name="PK_ROLE_ENUM_GET_DISTRO_UPGRADES" value="28"/>
			<member name="PK_ROLE_ENUM_UNKNOWN" value="29"/>
		</enum>
		<enum name="PkSigTypeEnum">
			<member name="PK_SIGTYPE_ENUM_GPG" value="0"/>
			<member name="PK_SIGTYPE_ENUM_UNKNOWN" value="1"/>
		</enum>
		<enum name="PkStatusEnum">
			<member name="PK_STATUS_ENUM_WAIT" value="0"/>
			<member name="PK_STATUS_ENUM_SETUP" value="1"/>
			<member name="PK_STATUS_ENUM_RUNNING" value="2"/>
			<member name="PK_STATUS_ENUM_QUERY" value="3"/>
			<member name="PK_STATUS_ENUM_INFO" value="4"/>
			<member name="PK_STATUS_ENUM_REMOVE" value="5"/>
			<member name="PK_STATUS_ENUM_REFRESH_CACHE" value="6"/>
			<member name="PK_STATUS_ENUM_DOWNLOAD" value="7"/>
			<member name="PK_STATUS_ENUM_INSTALL" value="8"/>
			<member name="PK_STATUS_ENUM_UPDATE" value="9"/>
			<member name="PK_STATUS_ENUM_CLEANUP" value="10"/>
			<member name="PK_STATUS_ENUM_OBSOLETE" value="11"/>
			<member name="PK_STATUS_ENUM_DEP_RESOLVE" value="12"/>
			<member name="PK_STATUS_ENUM_SIG_CHECK" value="13"/>
			<member name="PK_STATUS_ENUM_ROLLBACK" value="14"/>
			<member name="PK_STATUS_ENUM_TEST_COMMIT" value="15"/>
			<member name="PK_STATUS_ENUM_COMMIT" value="16"/>
			<member name="PK_STATUS_ENUM_REQUEST" value="17"/>
			<member name="PK_STATUS_ENUM_FINISHED" value="18"/>
			<member name="PK_STATUS_ENUM_CANCEL" value="19"/>
			<member name="PK_STATUS_ENUM_DOWNLOAD_REPOSITORY" value="20"/>
			<member name="PK_STATUS_ENUM_DOWNLOAD_PACKAGELIST" value="21"/>
			<member name="PK_STATUS_ENUM_DOWNLOAD_FILELIST" value="22"/>
			<member name="PK_STATUS_ENUM_DOWNLOAD_CHANGELOG" value="23"/>
			<member name="PK_STATUS_ENUM_DOWNLOAD_GROUP" value="24"/>
			<member name="PK_STATUS_ENUM_DOWNLOAD_UPDATEINFO" value="25"/>
			<member name="PK_STATUS_ENUM_REPACKAGING" value="26"/>
			<member name="PK_STATUS_ENUM_LOADING_CACHE" value="27"/>
			<member name="PK_STATUS_ENUM_SCAN_APPLICATIONS" value="28"/>
			<member name="PK_STATUS_ENUM_GENERATE_PACKAGE_LIST" value="29"/>
			<member name="PK_STATUS_ENUM_UNKNOWN" value="30"/>
		</enum>
		<enum name="PkUpdateStateEnum">
			<member name="PK_UPDATE_STATE_ENUM_STABLE" value="0"/>
			<member name="PK_UPDATE_STATE_ENUM_UNSTABLE" value="1"/>
			<member name="PK_UPDATE_STATE_ENUM_TESTING" value="2"/>
			<member name="PK_UPDATE_STATE_ENUM_UNKNOWN" value="3"/>
		</enum>
		<object name="PkCatalog" parent="GObject" type-name="PkCatalog" get-type="pk_catalog_get_type">
			<method name="cancel" symbol="pk_catalog_cancel">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="catalog" type="PkCatalog*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="pk_catalog_new">
				<return-type type="PkCatalog*"/>
			</constructor>
			<method name="process_files" symbol="pk_catalog_process_files">
				<return-type type="PkPackageList*"/>
				<parameters>
					<parameter name="catalog" type="PkCatalog*"/>
					<parameter name="filenames" type="gchar**"/>
				</parameters>
			</method>
			<signal name="progress" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="PkCatalog*"/>
					<parameter name="p0" type="guint"/>
					<parameter name="p1" type="char*"/>
				</parameters>
			</signal>
		</object>
		<object name="PkClient" parent="GObject" type-name="PkClient" get-type="pk_client_get_type">
			<method name="accept_eula" symbol="pk_client_accept_eula">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="eula_id" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="cancel" symbol="pk_client_cancel">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="download_packages" symbol="pk_client_download_packages">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="package_ids" type="gchar**"/>
					<parameter name="directory" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="error_print" symbol="pk_client_error_print">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="error_quark" symbol="pk_client_error_quark">
				<return-type type="GQuark"/>
			</method>
			<method name="get_allow_cancel" symbol="pk_client_get_allow_cancel">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="allow_cancel" type="gboolean*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_depends" symbol="pk_client_get_depends">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="filters" type="PkBitfield"/>
					<parameter name="package_ids" type="gchar**"/>
					<parameter name="recursive" type="gboolean"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_details" symbol="pk_client_get_details">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="package_ids" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_distro_upgrades" symbol="pk_client_get_distro_upgrades">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_files" symbol="pk_client_get_files">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="package_ids" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_old_transactions" symbol="pk_client_get_old_transactions">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="number" type="guint"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_package" symbol="pk_client_get_package">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="package" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_package_list" symbol="pk_client_get_package_list">
				<return-type type="PkPackageList*"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
				</parameters>
			</method>
			<method name="get_packages" symbol="pk_client_get_packages">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="filters" type="PkBitfield"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_progress" symbol="pk_client_get_progress">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="percentage" type="guint*"/>
					<parameter name="subpercentage" type="guint*"/>
					<parameter name="elapsed" type="guint*"/>
					<parameter name="remaining" type="guint*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_repo_list" symbol="pk_client_get_repo_list">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="filters" type="PkBitfield"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_require_restart" symbol="pk_client_get_require_restart">
				<return-type type="PkRestartEnum"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
				</parameters>
			</method>
			<method name="get_requires" symbol="pk_client_get_requires">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="filters" type="PkBitfield"/>
					<parameter name="package_ids" type="gchar**"/>
					<parameter name="recursive" type="gboolean"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_role" symbol="pk_client_get_role">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="role" type="PkRoleEnum*"/>
					<parameter name="text" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_status" symbol="pk_client_get_status">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="status" type="PkStatusEnum*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_tid" symbol="pk_client_get_tid">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
				</parameters>
			</method>
			<method name="get_update_detail" symbol="pk_client_get_update_detail">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="package_ids" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_updates" symbol="pk_client_get_updates">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="filters" type="PkBitfield"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_use_buffer" symbol="pk_client_get_use_buffer">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
				</parameters>
			</method>
			<method name="install_file" symbol="pk_client_install_file">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="trusted" type="gboolean"/>
					<parameter name="file_rel" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="install_files" symbol="pk_client_install_files">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="trusted" type="gboolean"/>
					<parameter name="files_rel" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="install_packages" symbol="pk_client_install_packages">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="package_ids" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="install_signature" symbol="pk_client_install_signature">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="type" type="PkSigTypeEnum"/>
					<parameter name="key_id" type="gchar*"/>
					<parameter name="package_id" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="is_caller_active" symbol="pk_client_is_caller_active">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="is_active" type="gboolean*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<constructor name="new" symbol="pk_client_new">
				<return-type type="PkClient*"/>
			</constructor>
			<method name="refresh_cache" symbol="pk_client_refresh_cache">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="force" type="gboolean"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="remove_packages" symbol="pk_client_remove_packages">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="package_ids" type="gchar**"/>
					<parameter name="allow_deps" type="gboolean"/>
					<parameter name="autoremove" type="gboolean"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="repo_enable" symbol="pk_client_repo_enable">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="repo_id" type="gchar*"/>
					<parameter name="enabled" type="gboolean"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="repo_set_data" symbol="pk_client_repo_set_data">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="repo_id" type="gchar*"/>
					<parameter name="parameter" type="gchar*"/>
					<parameter name="value" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="requeue" symbol="pk_client_requeue">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="reset" symbol="pk_client_reset">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="resolve" symbol="pk_client_resolve">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="filters" type="PkBitfield"/>
					<parameter name="packages" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="rollback" symbol="pk_client_rollback">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="transaction_id" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="search_details" symbol="pk_client_search_details">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="filters" type="PkBitfield"/>
					<parameter name="search" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="search_file" symbol="pk_client_search_file">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="filters" type="PkBitfield"/>
					<parameter name="search" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="search_group" symbol="pk_client_search_group">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="filters" type="PkBitfield"/>
					<parameter name="search" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="search_name" symbol="pk_client_search_name">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="filters" type="PkBitfield"/>
					<parameter name="search" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="set_locale" symbol="pk_client_set_locale">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="code" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="set_synchronous" symbol="pk_client_set_synchronous">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="synchronous" type="gboolean"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="set_tid" symbol="pk_client_set_tid">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="tid" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="set_use_buffer" symbol="pk_client_set_use_buffer">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="use_buffer" type="gboolean"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="update_packages" symbol="pk_client_update_packages">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="package_ids" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="update_system" symbol="pk_client_update_system">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="what_provides" symbol="pk_client_what_provides">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="filters" type="PkBitfield"/>
					<parameter name="provides" type="PkProvidesEnum"/>
					<parameter name="search" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<signal name="allow-cancel" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="allow_cancel" type="gboolean"/>
				</parameters>
			</signal>
			<signal name="caller-active-changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="is_active" type="gboolean"/>
				</parameters>
			</signal>
			<signal name="destroy" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="PkClient*"/>
				</parameters>
			</signal>
			<signal name="details" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="package_detail" type="gpointer"/>
				</parameters>
			</signal>
			<signal name="distro-upgrade" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="type" type="gpointer"/>
				</parameters>
			</signal>
			<signal name="error-code" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="code" type="guint"/>
					<parameter name="details" type="char*"/>
				</parameters>
			</signal>
			<signal name="eula-required" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="eula_id" type="char*"/>
					<parameter name="package_id" type="char*"/>
					<parameter name="vendor_name" type="char*"/>
					<parameter name="license_agreement" type="char*"/>
				</parameters>
			</signal>
			<signal name="files" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="package_id" type="char*"/>
					<parameter name="filelist" type="char*"/>
				</parameters>
			</signal>
			<signal name="finished" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="exit" type="guint"/>
					<parameter name="runtime" type="guint"/>
				</parameters>
			</signal>
			<signal name="message" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="message" type="guint"/>
					<parameter name="details" type="char*"/>
				</parameters>
			</signal>
			<signal name="package" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="obj" type="gpointer"/>
				</parameters>
			</signal>
			<signal name="progress-changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="percentage" type="guint"/>
					<parameter name="subpercentage" type="guint"/>
					<parameter name="elapsed" type="guint"/>
					<parameter name="remaining" type="guint"/>
				</parameters>
			</signal>
			<signal name="repo-detail" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="repo_id" type="char*"/>
					<parameter name="description" type="char*"/>
					<parameter name="enabled" type="gboolean"/>
				</parameters>
			</signal>
			<signal name="repo-signature-required" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="package_id" type="char*"/>
					<parameter name="repository_name" type="char*"/>
					<parameter name="key_url" type="char*"/>
					<parameter name="key_userid" type="char*"/>
					<parameter name="key_id" type="char*"/>
					<parameter name="key_fingerprint" type="char*"/>
					<parameter name="key_timestamp" type="char*"/>
					<parameter name="type" type="guint"/>
				</parameters>
			</signal>
			<signal name="require-restart" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="restart" type="guint"/>
					<parameter name="details" type="char*"/>
				</parameters>
			</signal>
			<signal name="status-changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="status" type="guint"/>
				</parameters>
			</signal>
			<signal name="transaction" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="tid" type="char*"/>
					<parameter name="timespec" type="char*"/>
					<parameter name="succeeded" type="gboolean"/>
					<parameter name="role" type="guint"/>
					<parameter name="duration" type="guint"/>
					<parameter name="data" type="char*"/>
				</parameters>
			</signal>
			<signal name="update-detail" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="client" type="PkClient*"/>
					<parameter name="update_detail" type="gpointer"/>
				</parameters>
			</signal>
		</object>
		<object name="PkConnection" parent="GObject" type-name="PkConnection" get-type="pk_connection_get_type">
			<constructor name="new" symbol="pk_connection_new">
				<return-type type="PkConnection*"/>
			</constructor>
			<method name="valid" symbol="pk_connection_valid">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="connection" type="PkConnection*"/>
				</parameters>
			</method>
			<signal name="connection-changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="connection" type="PkConnection*"/>
					<parameter name="connected" type="gboolean"/>
				</parameters>
			</signal>
		</object>
		<object name="PkControl" parent="GObject" type-name="PkControl" get-type="pk_control_get_type">
			<method name="allocate_transaction_id" symbol="pk_control_allocate_transaction_id">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
					<parameter name="tid" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="error_quark" symbol="pk_control_error_quark">
				<return-type type="GQuark"/>
			</method>
			<method name="get_actions" symbol="pk_control_get_actions">
				<return-type type="PkBitfield"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_backend_detail" symbol="pk_control_get_backend_detail">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
					<parameter name="name" type="gchar**"/>
					<parameter name="author" type="gchar**"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_filters" symbol="pk_control_get_filters">
				<return-type type="PkBitfield"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_groups" symbol="pk_control_get_groups">
				<return-type type="PkBitfield"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_mime_types" symbol="pk_control_get_mime_types">
				<return-type type="gchar**"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_network_state" symbol="pk_control_get_network_state">
				<return-type type="PkNetworkEnum"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_time_since_action" symbol="pk_control_get_time_since_action">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
					<parameter name="role" type="PkRoleEnum"/>
					<parameter name="seconds" type="guint*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<constructor name="new" symbol="pk_control_new">
				<return-type type="PkControl*"/>
			</constructor>
			<method name="set_proxy" symbol="pk_control_set_proxy">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
					<parameter name="proxy_http" type="gchar*"/>
					<parameter name="proxy_ftp" type="gchar*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="transaction_list_get" symbol="pk_control_transaction_list_get">
				<return-type type="gchar**"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
				</parameters>
			</method>
			<method name="transaction_list_print" symbol="pk_control_transaction_list_print">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
				</parameters>
			</method>
			<signal name="locked" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
					<parameter name="is_locked" type="gboolean"/>
				</parameters>
			</signal>
			<signal name="network-state-changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
					<parameter name="p0" type="guint"/>
				</parameters>
			</signal>
			<signal name="repo-list-changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
				</parameters>
			</signal>
			<signal name="restart-schedule" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
				</parameters>
			</signal>
			<signal name="transaction-list-changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
				</parameters>
			</signal>
			<signal name="updates-changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="control" type="PkControl*"/>
				</parameters>
			</signal>
		</object>
		<object name="PkExtra" parent="GObject" type-name="PkExtra" get-type="pk_extra_get_type">
			<method name="get_exec" symbol="pk_extra_get_exec">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="extra" type="PkExtra*"/>
					<parameter name="package" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_icon_name" symbol="pk_extra_get_icon_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="extra" type="PkExtra*"/>
					<parameter name="package" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_locale" symbol="pk_extra_get_locale">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="extra" type="PkExtra*"/>
				</parameters>
			</method>
			<method name="get_summary" symbol="pk_extra_get_summary">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="extra" type="PkExtra*"/>
					<parameter name="package" type="gchar*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="pk_extra_new">
				<return-type type="PkExtra*"/>
			</constructor>
			<method name="set_access" symbol="pk_extra_set_access">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="extra" type="PkExtra*"/>
					<parameter name="access" type="PkExtraAccess"/>
				</parameters>
			</method>
			<method name="set_data_locale" symbol="pk_extra_set_data_locale">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="extra" type="PkExtra*"/>
					<parameter name="package" type="gchar*"/>
					<parameter name="summary" type="gchar*"/>
				</parameters>
			</method>
			<method name="set_data_package" symbol="pk_extra_set_data_package">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="extra" type="PkExtra*"/>
					<parameter name="package" type="gchar*"/>
					<parameter name="icon_name" type="gchar*"/>
					<parameter name="exec" type="gchar*"/>
				</parameters>
			</method>
			<method name="set_database" symbol="pk_extra_set_database">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="extra" type="PkExtra*"/>
					<parameter name="filename" type="gchar*"/>
				</parameters>
			</method>
			<method name="set_locale" symbol="pk_extra_set_locale">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="extra" type="PkExtra*"/>
					<parameter name="locale" type="gchar*"/>
				</parameters>
			</method>
		</object>
		<object name="PkPackageList" parent="GObject" type-name="PkPackageList" get-type="pk_package_list_get_type">
			<method name="add" symbol="pk_package_list_add">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
					<parameter name="info" type="PkInfoEnum"/>
					<parameter name="ident" type="PkPackageId*"/>
					<parameter name="summary" type="gchar*"/>
				</parameters>
			</method>
			<method name="add_file" symbol="pk_package_list_add_file">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
					<parameter name="filename" type="gchar*"/>
				</parameters>
			</method>
			<method name="add_list" symbol="pk_package_list_add_list">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
					<parameter name="list" type="PkPackageList*"/>
				</parameters>
			</method>
			<method name="add_obj" symbol="pk_package_list_add_obj">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
					<parameter name="obj" type="PkPackageObj*"/>
				</parameters>
			</method>
			<method name="clear" symbol="pk_package_list_clear">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
				</parameters>
			</method>
			<method name="contains" symbol="pk_package_list_contains">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
					<parameter name="package_id" type="gchar*"/>
				</parameters>
			</method>
			<method name="contains_obj" symbol="pk_package_list_contains_obj">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
					<parameter name="obj" type="PkPackageObj*"/>
				</parameters>
			</method>
			<method name="get_obj" symbol="pk_package_list_get_obj">
				<return-type type="PkPackageObj*"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
					<parameter name="item" type="guint"/>
				</parameters>
			</method>
			<method name="get_size" symbol="pk_package_list_get_size">
				<return-type type="guint"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="pk_package_list_new">
				<return-type type="PkPackageList*"/>
			</constructor>
			<method name="remove" symbol="pk_package_list_remove">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
					<parameter name="package_id" type="gchar*"/>
				</parameters>
			</method>
			<method name="remove_obj" symbol="pk_package_list_remove_obj">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
					<parameter name="obj" type="PkPackageObj*"/>
				</parameters>
			</method>
			<method name="sort" symbol="pk_package_list_sort">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
				</parameters>
			</method>
			<method name="sort_info" symbol="pk_package_list_sort_info">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
				</parameters>
			</method>
			<method name="sort_summary" symbol="pk_package_list_sort_summary">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
				</parameters>
			</method>
			<method name="to_file" symbol="pk_package_list_to_file">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
					<parameter name="filename" type="gchar*"/>
				</parameters>
			</method>
			<method name="to_string" symbol="pk_package_list_to_string">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
				</parameters>
			</method>
			<method name="to_strv" symbol="pk_package_list_to_strv">
				<return-type type="gchar**"/>
				<parameters>
					<parameter name="plist" type="PkPackageList*"/>
				</parameters>
			</method>
		</object>
		<object name="PkTaskList" parent="GObject" type-name="PkTaskList" get-type="pk_task_list_get_type">
			<method name="contains_role" symbol="pk_task_list_contains_role">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="tlist" type="PkTaskList*"/>
					<parameter name="role" type="PkRoleEnum"/>
				</parameters>
			</method>
			<method name="free" symbol="pk_task_list_free">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="tlist" type="PkTaskList*"/>
				</parameters>
			</method>
			<method name="get_item" symbol="pk_task_list_get_item">
				<return-type type="PkTaskListItem*"/>
				<parameters>
					<parameter name="tlist" type="PkTaskList*"/>
					<parameter name="item" type="guint"/>
				</parameters>
			</method>
			<method name="get_size" symbol="pk_task_list_get_size">
				<return-type type="guint"/>
				<parameters>
					<parameter name="tlist" type="PkTaskList*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="pk_task_list_new">
				<return-type type="PkTaskList*"/>
			</constructor>
			<method name="print" symbol="pk_task_list_print">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="tlist" type="PkTaskList*"/>
				</parameters>
			</method>
			<method name="refresh" symbol="pk_task_list_refresh">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="tlist" type="PkTaskList*"/>
				</parameters>
			</method>
			<signal name="changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="tlist" type="PkTaskList*"/>
				</parameters>
			</signal>
			<signal name="error-code" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="tlist" type="PkTaskList*"/>
					<parameter name="client" type="gpointer"/>
					<parameter name="code" type="guint"/>
					<parameter name="details" type="char*"/>
				</parameters>
			</signal>
			<signal name="finished" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="tlist" type="PkTaskList*"/>
					<parameter name="client" type="gpointer"/>
					<parameter name="exit" type="guint"/>
					<parameter name="runtime" type="guint"/>
				</parameters>
			</signal>
			<signal name="message" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="tlist" type="PkTaskList*"/>
					<parameter name="client" type="gpointer"/>
					<parameter name="message" type="guint"/>
					<parameter name="details" type="char*"/>
				</parameters>
			</signal>
			<signal name="status-changed" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="tlist" type="PkTaskList*"/>
				</parameters>
			</signal>
		</object>
		<constant name="PK_CLIENT_PERCENTAGE_INVALID" type="int" value="101"/>
		<constant name="PK_DBUS_INTERFACE" type="char*" value="org.freedesktop.PackageKit"/>
		<constant name="PK_DBUS_INTERFACE_TRANSACTION" type="char*" value="org.freedesktop.PackageKit.Transaction"/>
		<constant name="PK_DBUS_PATH" type="char*" value="/org/freedesktop/PackageKit"/>
		<constant name="PK_DBUS_SERVICE" type="char*" value="org.freedesktop.PackageKit"/>
		<constant name="PK_EXTRA_DEFAULT_DATABASE" type="char*" value="/var/lib/PackageKit/extra-data.db"/>
		<constant name="PK_PACKAGE_IDS_DELIM" type="char*" value="&amp;"/>
		<constant name="PK_SERVICE_PACK_GROUP_NAME" type="char*" value="PackageKit Service Pack"/>
	</namespace>
</api>
