-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 管理定制化操作

local log = require 'mc.logging'
local class = require 'mc.class'
local certificate_authentication = require 'domain.certificate_authentication'
local certificate_authentication_ipmi = require 'interface.ipmi.certificate_authentication_ipmi'
local config_mgmt = require 'interface.config_mgmt.config_mgmt'
local singleton = require 'mc.singleton'
local operation_logger = require 'interface.operation_logger'

local AccountServiceCustomization =
    require 'interface.config_mgmt.manufacture.customization.account_service_customization'
local SessionServiceCustomization =
    require 'interface.config_mgmt.manufacture.customization.session_service_customization'
local LDAPCustomization = require 'interface.config_mgmt.manufacture.customization.ldap_customization'
local RemoteGroupsCustomization = require 'interface.config_mgmt.manufacture.customization.remote_groups_customization'

local CUSTOM_LDAP_CONF_REGEX<const> = "^(BMCSet_LDAP[^%d]*)(%d+)$"

local function check_id_valid(set_group, id)
    if not set_group then
        return id >= 1 and id <= 6
    else
        local group_id = id >> 4
        local controller_id = id & 0xf
        return (controller_id >= 1 and controller_id <= 6) and (group_id >= 0 and group_id <= 4)
    end
end

local CustomSettings = class(config_mgmt)

function CustomSettings:ctor()
    self.m_certificate_authentication = certificate_authentication.get_instance()
    self.m_certificate_authentication_ipmi = certificate_authentication_ipmi.get_instance()

    self.m_remote_group_map = {}
end

function CustomSettings:init_remote_group_id_collection()
    for controller_id = 1, 6 do
        for group_id = 0, 4 do
            local init_remote_group_id = (group_id << 4 ) | controller_id
            self.m_remote_group_map[init_remote_group_id] = -1
        end
    end
    for id, group in pairs(self.m_remote_group_collection.m_db_remote_group_collection) do
        local controller_id = group:get_remote_group_controller_id()
        local controller_inner_id = group:get_remote_group_controller_inner_id()
        local custom_remote_group_id = ((controller_inner_id - 1) << 4 ) | controller_id
        self.m_remote_group_map[custom_remote_group_id] = id
    end
end

local custom_settings_adapter = {
    Custom_FailedLoginCount = {
        import = AccountServiceCustomization.set_account_lockout_threshold,
        export = AccountServiceCustomization.get_account_lockout_threshold
    },
    Custom_ForbidLoginTime = {
        import_convert = AccountServiceCustomization.convert_account_lockout_duration,
        import = AccountServiceCustomization.set_account_lockout_duration,
        export = AccountServiceCustomization.get_account_lockout_duration
    },
    BMCSet_WebSessionMode = {
        import_convert = SessionServiceCustomization.convert_web_mode,
        import = SessionServiceCustomization.set_web_mode,
        export = SessionServiceCustomization.get_web_mode
    },
    BMCSet_SessionTimeout = {
        import_convert = SessionServiceCustomization.convert_web_timeout,
        import = SessionServiceCustomization.set_web_timeout,
        export = SessionServiceCustomization.get_web_timeout
    },
    BMCSet_RedfishMaxConcurrentSessions = {
        import = SessionServiceCustomization.set_redfish_session_max_count,
        export = SessionServiceCustomization.get_redfish_session_max_count,
    },
    BMCSet_RemoteGroupAllowedLoginInterfaces = {
        import = operation_logger.proxy(function(self, ctx, value)
            RemoteGroupsCustomization.set_allowed_login_interfaces(self, ctx, value)
        end, 'SetAllowedLoginInterfaces'),
        export = RemoteGroupsCustomization.get_allowed_login_interfaces
    },
    BMCSet_WebMaxConcurrentSessions = {
        import = SessionServiceCustomization.set_web_session_max_count,
        export = SessionServiceCustomization.get_web_session_max_count,
    },
    BMCSet_KVMTimeout = {
        import_convert = SessionServiceCustomization.convert_kvm_timeout,
        import = SessionServiceCustomization.set_kvm_timeout,
        export = SessionServiceCustomization.get_kvm_timeout
    },
    BMCSet_VNCTimeout = {
        import_convert = SessionServiceCustomization.convert_vnc_timeout,
        import = SessionServiceCustomization.set_vnc_timeout,
        export = SessionServiceCustomization.get_vnc_timeout
    },
    BMCSet_RedfishSessionTimeout = {
        import_convert = SessionServiceCustomization.convert_redfish_timeout,
        import = SessionServiceCustomization.set_redfish_timeout,
        export = SessionServiceCustomization.get_redfish_timeout
    },
    BMCSet_CLISessionTimeout = {
        import_convert = SessionServiceCustomization.convert_cli_timeout,
        import = SessionServiceCustomization.set_cli_timeout,
        export = SessionServiceCustomization.get_cli_timeout
    },
    BMCSet_LDAPEnable = {
        import_convert = LDAPCustomization.convert_ldap_enable,
        import = LDAPCustomization.set_ldap_enable,
        export = LDAPCustomization.get_ldap_enable
    },
    BMCSet_LDAPHostAddr = {
        import = LDAPCustomization.set_ldap_host_addr,
        export = LDAPCustomization.get_ldap_host_addr
    },
    BMCSet_LDAPUserDomain = {
        import = LDAPCustomization.set_ldap_user_domain,
        export = LDAPCustomization.get_ldap_user_domain
    },
    BMCSet_LDAPPort = {
        import = LDAPCustomization.set_ldap_port,
        export = LDAPCustomization.get_ldap_port
    },
    BMCSet_LDAPCertStatus = {
        import = LDAPCustomization.set_ldap_cert_status,
        export = LDAPCustomization.get_ldap_cert_status
    },
    BMCSet_LDAPGroupName = {
        import = LDAPCustomization.set_ldap_group_name,
        export = LDAPCustomization.get_ldap_group_name
    },
    BMCSet_LDAPGroupPermitRuleIds = {
        import = LDAPCustomization.set_ldap_group_permit_rule_ids,
        export = LDAPCustomization.get_ldap_group_permit_rule_ids
    },
    BMCSet_LDAPGroupLoginInterface = {
        import = LDAPCustomization.set_ldap_group_login_interface,
        export = LDAPCustomization.get_ldap_group_login_interface
    },
    BMCSet_LDAPGroupFolder = {
        import = LDAPCustomization.set_ldap_group_folder,
        export = LDAPCustomization.get_ldap_group_folder
    },
    BMCSet_LDAPGroupUserRoleId = {
        import = LDAPCustomization.set_ldap_group_user_role_id,
        export = LDAPCustomization.get_ldap_group_user_role_id
    }
}

local session_timeout_map = {
    ['BMCSet_SessionTimeout'] = true,
    ['BMCSet_VNCTimeout'] = true,
    ['BMCSet_KVMTimeout'] = true,
    ['BMCSet_RedfishSessionTimeout'] = true,
    ['BMCSet_CLISessionTimeout'] = true
}

function CustomSettings:on_import(ctx, object)
    local custom_settings = object.CustomSettings
    if not custom_settings or type(custom_settings) ~= 'table' then
        log:error('Import data(%s) is invalid', object)
        return
    end

    ctx.operation_log = { params = {} }

    for custom_setting_name, custom_setting in pairs(custom_settings) do
        local match_ldap_conf = string.match(custom_setting_name, "(BMCSet_LDAP)")
        if match_ldap_conf and string.match(custom_setting_name, "%d$") then
            self:import_ldap_custom_settings(ctx, custom_setting_name, custom_setting)
            goto continue
        end
        if not custom_settings_adapter[custom_setting_name] then
            goto continue
        end

        local custom_setting_funcs = custom_settings_adapter[custom_setting_name]
        local custom_value = custom_setting.Value
        if custom_setting_funcs.import_convert then
            custom_value = custom_setting_funcs.import_convert(custom_settings)
        end

        local current_value = custom_setting_funcs.export(self)
        if session_timeout_map[custom_setting_name] then
            current_value = current_value * 60
        end
        if current_value == custom_value or not custom_setting_funcs.import then
            goto continue
        end

        custom_setting_funcs.import(self, ctx, custom_value)
        log:notice('Import %s successfully in customize config.', custom_setting_name)
        ::continue::
    end
    LDAPCustomization.create_remote_groups(self, ctx)
    ctx.operation_log = nil
end

function CustomSettings:on_export(ctx)
    local export_data = {}
    export_data.CustomSettings = {}

    for custom_setting_name, custom_setting_funcs in pairs(custom_settings_adapter) do

        local match_ldap_conf = string.match(custom_setting_name, "(BMCSet_LDAP)")
        if match_ldap_conf and custom_setting_name ~= "BMCSet_LDAPEnable" then
            self:export_ldap_custom_settings(custom_setting_name, custom_setting_funcs, export_data.CustomSettings)
        elseif custom_setting_funcs.export then
            export_data.CustomSettings[custom_setting_name] = custom_setting_funcs.export(self)
        end
    end

    return export_data
end

function CustomSettings:import_ldap_custom_settings(ctx, custom_ldap_conf_name, custom_setting)
    local ldap_conf_str, custom_id = string.match(custom_ldap_conf_name, CUSTOM_LDAP_CONF_REGEX)
    custom_id = tonumber(custom_id)
    local match_ldap_group_conf = string.match(custom_ldap_conf_name, "(LDAPGroup)")
    if not check_id_valid(match_ldap_group_conf, custom_id) then
        log:error('custom_setting ldap config failed, %s%d is invalid', ldap_conf_str, custom_id)
        return
    end

    local ldap_setting_funcs = custom_settings_adapter[ldap_conf_str]
    local ldap_value = custom_setting.Value

    local current_value = match_ldap_group_conf and
        ldap_setting_funcs.export(self, self.m_remote_group_map[custom_id]) or
        ldap_setting_funcs.export(self, custom_id)
    if current_value == ldap_value or not ldap_setting_funcs.import then
        return
    end
    ldap_setting_funcs.import(self, ctx, custom_id, ldap_value)
end

function CustomSettings:export_ldap_custom_settings(ldap_conf_name, ldap_conf_funcs, custom_settings)
    local match_ldap_group_conf = string.match(ldap_conf_name, "(LDAPGroup)")
    if match_ldap_group_conf then
        for custom_group_id, group_id in pairs(self.m_remote_group_map) do
            local bmc_set_group = string.format("%s%d", ldap_conf_name, custom_group_id)
            custom_settings[bmc_set_group] = ldap_conf_funcs.export(self, group_id)
        end
    else
        for controller_id = 1, 6 do
            local bmc_set_ldap = string.format("%s%d", ldap_conf_name, controller_id)
            custom_settings[bmc_set_ldap] = ldap_conf_funcs.export(self, controller_id)
        end
    end
end

return singleton(CustomSettings)