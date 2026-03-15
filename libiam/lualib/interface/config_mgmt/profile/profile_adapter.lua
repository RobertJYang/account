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
-- Description: 管理配置导入导出

local mc_utils = require 'mc.utils'
local custom_messages = require 'messages.custom'
local iam_enum = require 'class.types.types'
local class = require 'mc.class'
local config_mgmt = require 'interface.config_mgmt.config_mgmt'
local singleton = require 'mc.singleton'
local account_utils = require 'infrastructure.account_utils'
local utils = require 'utils'

local operation_logger = require 'interface.operation_logger'
local AccountServiceProfile = require 'interface.config_mgmt.profile.account_service_profile'
local SessionServiceProfile = require 'interface.config_mgmt.profile.session_service_profile'
local LdapControllerProfile = require 'interface.config_mgmt.profile.ldap_controller_profile'
local LdapConfigProfile = require 'interface.config_mgmt.profile.ldap_config_profile'
local RemoteGroupProfile = require 'interface.config_mgmt.profile.remote_group_profile'

local ProfileAdapter = class(config_mgmt)

function ProfileAdapter:ctor()
    self.m_remote_group_id_collection = {}
end

function ProfileAdapter:init_remote_group_id_collection()
    self.m_remote_group_id_collection = {}
    for id, group in pairs(self.m_remote_group_collection.m_db_remote_group_collection) do
        self.m_remote_group_id_collection[group:get_group_mdb_id()] = id
    end
end

local profile_adapter = {
    SecurityEnhance = {
        AuthFailMax = {
            import = operation_logger.proxy(function(self, ctx, value)
                ctx.operation_log.params = { threshold = value }
                AccountServiceProfile.set_account_lockout_threshold(self, ctx, value)
            end, 'AccountLockoutThreshold'),
            export = AccountServiceProfile.get_account_lockout_threshold
        },
        AuthFailLockTime = {
            import = operation_logger.proxy(function(self, ctx, value)
                -- 入参整除60，取分钟
                ctx.operation_log.params = { duration = value // 60 }
                AccountServiceProfile.set_account_lockout_duration(self, ctx, value)
            end, 'AccountLockoutDuration'),
            export = AccountServiceProfile.get_account_lockout_duration
        }
    },
    Session = {
        Timeout = {
            import = operation_logger.proxy(function(self, ctx, value)
                -- 传入value单位秒，转分钟除以60
                ctx.operation_log.params = { type = 'GUI', time = value // 60, timeunit = 'minutes' }
                SessionServiceProfile.set_web_timeout(self, ctx, value)
            end, 'SessionTimeout'),
            export = SessionServiceProfile.get_web_timeout
        },
        RedfishSessionTimeout = {
            import = operation_logger.proxy(function(self, ctx, value)
                -- 传入value单位秒
                ctx.operation_log.params = { type = 'Redfish', time = value, timeunit = 'seconds' }
                SessionServiceProfile.set_redfish_timeout(self, ctx, value)
            end, 'SessionTimeout'),
            export = SessionServiceProfile.get_redfish_timeout
        },
        CLISessionTimeout = {
            import = operation_logger.proxy(function(self, ctx, value)
                -- 传入value单位秒，转分钟除以60
                ctx.operation_log.params = { type = 'CLI', time = value // 60, timeunit = 'minutes' }
                SessionServiceProfile.set_cli_timeout(self, ctx, value)
            end, 'SessionTimeout'),
            export = SessionServiceProfile.get_cli_timeout
        },
        Mode = {
            import = operation_logger.proxy(function(self, ctx, value)
                local session_mode = iam_enum.OccupationMode.new(value)
                local session_mode_name = session_mode == iam_enum.OccupationMode.Shared and 'share' or 'exclusive'
                ctx.operation_log.params = { type = tostring(iam_enum.SessionType.GUI), mode = session_mode_name }
                SessionServiceProfile.set_web_mode(self, ctx, value)
            end, 'SessionMode'),
            export = SessionServiceProfile.get_web_mode
        }
    },
    LDAPCommon = {
        Enable = {
            import = operation_logger.proxy(function(self, ctx, value)
                ctx.operation_log.params = { state = value and 'Enabled' or 'Disabled' }
                LdapConfigProfile.set_ldap_enabled(self, ctx, value)
            end, 'LdapEnabled'),
            export = LdapConfigProfile.get_ldap_enabled
        }
    },
    LDAPServer = {
        isObjectArray = true,
        instance_ids = { 1, 2, 3, 4, 5, 6 },
        Id = {
            import = LdapControllerProfile.set_ldap_controller_id,
            export = LdapControllerProfile.get_ldap_controller_id
        },
        Enable = {
            import = operation_logger.proxy(function(self, ctx, controller_id, value)
                ctx.operation_log.params = { id = controller_id, state = value and 'Enabled' or 'Disabled' }
                LdapControllerProfile.set_ldap_controller_enabled(self, ctx, controller_id, value)
            end, 'LdapControllerEnabled'),
            export = LdapControllerProfile.get_ldap_controller_enabled
        },
        HostAddr = {
            import = operation_logger.proxy(function(self, ctx, controller_id, value)
                ctx.operation_log.params = { id = controller_id, addr = value }
                LdapControllerProfile.set_ldap_controller_hostaddr(self, ctx, controller_id, value)
            end, 'LdapControllerHostAddr'),
            export = LdapControllerProfile.get_ldap_controller_hostaddr
        },
        Port = {
            import = operation_logger.proxy(function(self, ctx, controller_id, value)
                ctx.operation_log.params = { id = controller_id, port = value }
                LdapControllerProfile.set_ldap_controller_port(self, ctx, controller_id, value)
            end, 'LdapControllerPort'),
            export = LdapControllerProfile.get_ldap_controller_port
        },
        UserDomain = {
            import = operation_logger.proxy(function(self, ctx, controller_id, value)
                ctx.operation_log.params = { id = controller_id, domain = value }
                LdapControllerProfile.set_ldap_controller_domain(self, ctx, controller_id, value)
            end, 'LdapControllerDomain'),
            export = LdapControllerProfile.get_ldap_controller_domain
        },
        CertStatus = {
            import = operation_logger.proxy(function(self, ctx, controller_id, value)
                ctx.operation_log.params = { id = controller_id, state = value and 'Enable' or 'Disable' }
                LdapControllerProfile.set_ldap_controller_cert_verify_enabled(self, ctx, controller_id, value)
            end, 'LdapControllerCertVerifyEnabled'),
            export = LdapControllerProfile.get_ldap_controller_cert_verify_enabled
        },
        CertificateVerificationLevel = {
            import = operation_logger.proxy(function(self, ctx, controller_id, value)
                ctx.operation_log.params = { id = controller_id, level = value }
                LdapControllerProfile.set_ldap_controller_cert_verify_level(self, ctx, controller_id, value)
            end, 'LdapControllerCertVerifyLevel'),
            export = LdapControllerProfile.get_ldap_controller_cert_verify_level
        },
        Folder = {
            import = operation_logger.proxy(function(self, ctx, controller_id, value)
                ctx.operation_log.params = { id = controller_id, folder = value }
                LdapControllerProfile.set_ldap_controller_folder(self, ctx, controller_id, value)
            end, 'LdapControllerFolder'),
            export = LdapControllerProfile.get_ldap_controller_folder
        },
        BindDN = {
            import = operation_logger.proxy(function(self, ctx, controller_id, value)
                ctx.operation_log.params = { id = controller_id, bind_dn = value }
                LdapControllerProfile.set_ldap_controller_bind_dn(self, ctx, controller_id, value)
            end, 'LdapControllerBindDn'),
            export = LdapControllerProfile.get_ldap_controller_bind_dn
        }
    },
    LDAPGroup = {
        isObjectArray = true,
        instance_ids = {
            'LDAP1_1', 'LDAP1_2', 'LDAP1_3', 'LDAP1_4', 'LDAP1_5',
            'LDAP2_1', 'LDAP2_2', 'LDAP2_3', 'LDAP2_4', 'LDAP2_5',
            'LDAP3_1', 'LDAP3_2', 'LDAP3_3', 'LDAP3_4', 'LDAP3_5',
            'LDAP4_1', 'LDAP4_2', 'LDAP4_3', 'LDAP4_4', 'LDAP4_5',
            'LDAP5_1', 'LDAP5_2', 'LDAP5_3', 'LDAP5_4', 'LDAP5_5',
            'LDAP6_1', 'LDAP6_2', 'LDAP6_3', 'LDAP6_4', 'LDAP6_5'},
        Id = {
            import = RemoteGroupProfile.set_remote_group_id,
            export = RemoteGroupProfile.get_remote_group_id
        },
        SID = {
            import = operation_logger.proxy(function(self, ctx, group_id, value)
                RemoteGroupProfile.set_remote_group_sid(self, ctx, group_id, value)
            end, 'SID'),
            export = RemoteGroupProfile.get_remote_group_sid
        },
        GroupName = {
            import = operation_logger.proxy(function(self, ctx, group_id, value)
                RemoteGroupProfile.set_remote_group_name(self, ctx, group_id, value)
            end, 'RemoteGroupName'),
            export = RemoteGroupProfile.get_remote_group_name
        },
        GroupUserRoleId = {
            import = operation_logger.proxy(function(self, ctx, group_id, value)
                RemoteGroupProfile.set_remote_group_role_id(self, ctx, group_id, value)
            end, 'RemoteGroupRoleId'),
            export = RemoteGroupProfile.get_remote_group_role_id
        },
        GroupFolder = {
            import = operation_logger.proxy(function(self, ctx, group_id, value)
                RemoteGroupProfile.set_remote_group_folder(self, ctx, group_id, value)
            end, 'RemoteGroupFolder'),
            export = RemoteGroupProfile.get_remote_group_folder
        },
        GroupPermitRuleIds = {
            import = operation_logger.proxy(function(self, ctx, group_id, value)
                RemoteGroupProfile.set_remote_group_permit_rule_ids(self, ctx, group_id, value)
            end, 'LoginRule'),
            export = RemoteGroupProfile.get_remote_group_permit_rule_ids
        },
        GroupLoginInterface = {
            import = operation_logger.proxy(function(self, ctx, group_id, value)
                RemoteGroupProfile.set_remote_group_login_interface(self, ctx, group_id, value)
            end, 'LoginInterface'),
            export = RemoteGroupProfile.get_remote_group_login_interface
        }
    }
}

local function is_object_array(T)
    if type(T) ~= 'table' or #T == 0 then
        return false
    end

    local len = #T
    for key, value in pairs(T) do
        if type(key) ~= 'number' or key > len then
            return false
        end
        if type(value) ~= 'table' then
            return false
        end
    end

    return true
end

local TAB_PROP_CONV = {
    GroupLoginInterface = utils.cover_interface_str_to_num,
    GroupPermitRuleIds = account_utils.covert_login_rule_ids_str_to_num,
}

local function verify_property_not_change(property_name, property_value, current_value)
    if type(current_value) ~= 'table' then
        return property_value == current_value
    end
    if TAB_PROP_CONV[property_name] then
        return TAB_PROP_CONV[property_name](property_value) == TAB_PROP_CONV[property_name](current_value)
    else
        return mc_utils.table_compare(current_value, property_value)
    end
end

function ProfileAdapter:import_instances(ctx, class_name, instance_id, property_name, property)
    if property.Import == false then
        return
    end
    local property_value = property.Value
    local state = pcall(function()
        if not (profile_adapter[class_name][property_name] and profile_adapter[class_name][property_name].import) then
            return
        end
        local ok, current_value = pcall(function()
            return profile_adapter[class_name][property_name].export(self, instance_id)
        end)
        if ok and verify_property_not_change(property_name, property_value, current_value) then
            return
        end
        profile_adapter[class_name][property_name].import(self, ctx, instance_id, property_value)
    end)
    if not state then
        local err_msg = string.format("/%s/%s/%s", class_name, instance_id, property_name)
        error(custom_messages.CollectingConfigurationErrorDesc(err_msg))
    end
end

function ProfileAdapter:import_property(ctx, class_name, property_name, property_value)
    local ok = pcall(function()
        if not (profile_adapter[class_name][property_name] and profile_adapter[class_name][property_name].import) then
            return
        end
        local current_value = profile_adapter[class_name][property_name].export(self)
        if verify_property_not_change(property_name, property_value, current_value) then
            return
        end
        profile_adapter[class_name][property_name].import(self, ctx, property_value)
    end)
    if not ok then
        local err_msg = string.format("/%s/%s", class_name, property_name)
        error(custom_messages.CollectingConfigurationErrorDesc(err_msg))
    end
end

function ProfileAdapter:import_handle(ctx, class_name, profile_class)
    if is_object_array(profile_class) then
        for _, instance in ipairs(profile_class) do
            if instance.Id.Import == false then
                goto continue
            end
            local instance_id = instance.Id.Value
            local ok = pcall(function()
                profile_adapter[class_name].Id.import(self, ctx, instance_id)
            end)
            if not ok then
                local err_msg = string.format("/%s/%s/%s", class_name, instance_id, 'Id')
                error(custom_messages.CollectingConfigurationErrorDesc(err_msg))
            end
            for property_name, property_value in pairs(instance) do
                self:import_instances(ctx, class_name, instance_id, property_name, property_value)
            end
            ::continue::
        end
    else
        for property_name, property_value in pairs(profile_class) do
            if property_value.Import ~= false then
                self:import_property(ctx, class_name, property_name, property_value.Value)
            end
        end
    end
end

function ProfileAdapter:on_import(ctx, object)
    ctx.operation_log = { params = {} }

    for class_name, object_class in pairs(object) do
        if not profile_adapter[class_name] then
            goto continue
        end
        self:import_handle(ctx, class_name, object_class)
        ::continue::
    end
    RemoteGroupProfile.create_remote_groups(self, ctx)

    ctx.operation_log = nil
end

function ProfileAdapter:export_instances(export_data, class_name, cls, instance_id)
    if not cls.Id.export(self, instance_id) then
        goto continue
    end
    local instance = {}
    for property_name, property in pairs(cls) do
        if type(property) == 'table' and property.export then
            instance[property_name] = property.export(self, instance_id)
        end
    end
    export_data[class_name][#export_data[class_name] + 1] = instance
    ::continue::
end

function ProfileAdapter:on_export(ctx)
    local export_data = {}

    for class_name, profile_class in pairs(profile_adapter) do
        export_data[class_name] = {}
        if profile_class.isObjectArray then
            for _, instance_id in ipairs(profile_class.instance_ids) do
                self:export_instances(export_data, class_name, profile_class, instance_id)
            end
        else
            for property_name, property in pairs(profile_class) do
                export_data[class_name][property_name] = property.export(self)
            end
        end
    end

    return export_data
end

return singleton(ProfileAdapter)
