-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 管理定制化操作

local log = require 'mc.logging'
local class = require 'mc.class'
local account_service_ipmi = require 'interface.ipmi.account_service_ipmi'
local config_mgmt = require 'interface.config_mgmt.config_mgmt'
local singleton = require 'mc.singleton'
local operation_logger = require 'interface.operation_logger'

local AccountServiceCustomization =
    require 'interface.config_mgmt.manufacture.customization.account_service_customization'
local AccountCustomization = require 'interface.config_mgmt.manufacture.customization.account_customization'
local PasswordValidatorCustomization =
    require 'interface.config_mgmt.manufacture.customization.password_validator_customization'

local function get_oem_account_id(custom_oem_conf_name)
    local CUSTOM_OEM_CONF_REGEX<const> = "^BMCSet_OEMName(%d+)$"
    local OEM_ACCOUNT_ID_OFFSET<const> = 100
    local custom_id = string.match(custom_oem_conf_name, CUSTOM_OEM_CONF_REGEX)
    custom_id = tonumber(custom_id) + OEM_ACCOUNT_ID_OFFSET
    return custom_id
end

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
    self.m_account_service_ipmi = account_service_ipmi.get_instance()
    self.m_remote_group_map = {}
end

local custom_settings_adapter = {
    Custom_AdminWritable = {
        import = operation_logger.proxy(function(self, ctx, value)
            AccountCustomization.set_default_admin_writable(self, ctx, value)
        end, 'SetAccountWritable'),
        export = AccountCustomization.get_default_admin_writable
    },
    Custom_ExpiredTime = {
        import = AccountServiceCustomization.set_max_password_valid_days,
        export = AccountServiceCustomization.get_max_password_valid_days
    },
    Custom_MinimumPwdAge = {
        import = AccountServiceCustomization.set_min_password_valid_days,
        export = AccountServiceCustomization.get_min_password_valid_days
    },
    Custom_SamePwdCheckCount = {
        import = AccountServiceCustomization.set_history_password_count,
        export = AccountServiceCustomization.get_history_password_count
    },
    Custom_ExcludeUserID = {
        import = AccountServiceCustomization.set_emergency_account,
        export = AccountServiceCustomization.get_emergency_account
    },
    Custom_InactiveTimelimit = {
        import = AccountServiceCustomization.set_inactive_time_threshold,
        export = AccountServiceCustomization.get_inactive_time_threshold
    },
    BMCSet_WeakPasswdDictionaryCheck = {
        import_convert = AccountServiceCustomization.convert_weak_pwd_dictionary_enable,
        import = AccountServiceCustomization.set_weak_pwd_dictionary_enable,
        export = AccountServiceCustomization.get_weak_pwd_dictionary_enable
    },
    BMCSet_InitialPwdPrompt = {
        import_convert = AccountServiceCustomization.convert_initial_password_prompt_enable,
        import = AccountServiceCustomization.set_initial_password_prompt_enable,
        export = AccountServiceCustomization.get_initial_password_prompt_enable
    },
    BMCSet_InitialPasswordNeedModify = {
        import = AccountServiceCustomization.set_first_login_enable,
        export = AccountServiceCustomization.get_first_login_enable
    },
    BMCSet_TrapSNMPv3UserID = {
        import = AccountServiceCustomization.set_snmp_v3_trap_account,
        export = AccountServiceCustomization.get_snmp_v3_trap_account
    },
    BMCSet_VNCPermitRuleIds = {
        import_convert = AccountCustomization.convert_vnc_login_rule_ids,
        import = AccountCustomization.set_vnc_login_rule_ids,
        export = AccountCustomization.get_vnc_login_rule_ids
    },
    BMCSet_LocalAccountAllowedLoginInterfaces = {
        import = operation_logger.proxy(function(self, ctx, value)
            AccountServiceCustomization.set_local_allowed_login_interfaces(self, ctx, value)
        end, 'SetAllowedLoginInterfaces'),
        export = AccountServiceCustomization.get_local_allowed_login_interfaces
    },
    BMCSet_LongPasswordEnable = {
        import_convert = AccountServiceCustomization.convert_long_community_enable,
        import = AccountServiceCustomization.set_long_community_enable,
        export = AccountServiceCustomization.get_long_community_enable
    },
    BMCSet_OEMName = {
        import = AccountCustomization.set_oem_account_name,
        export = AccountCustomization.get_oem_account_name,
    },
    BMCSet_LocalAccountPasswordRulePolicy = {
        import = PasswordValidatorCustomization.set_local_account_password_policy,
        export = PasswordValidatorCustomization.get_local_account_password_policy
    },
    BMCSet_LocalAccountPasswordPattern = {
        import = PasswordValidatorCustomization.set_local_account_password_pattern,
        export = PasswordValidatorCustomization.get_local_account_password_pattern
    },
    BMCSet_SnmpCommunityPasswordRulePolicy = {
        import = PasswordValidatorCustomization.set_snmp_community_policy,
        export = PasswordValidatorCustomization.get_snmp_community_policy
    },
    BMCSet_SnmpCommunityPasswordPattern = {
        import = PasswordValidatorCustomization.set_snmp_community_pattern,
        export = PasswordValidatorCustomization.get_snmp_community_pattern
    },
    BMCSet_VNCPasswordRulePolicy = {
        import = PasswordValidatorCustomization.set_vnc_password_policy,
        export = PasswordValidatorCustomization.get_vnc_password_policy
    },
    BMCSet_VNCPasswordPattern = {
        import = PasswordValidatorCustomization.set_vnc_password_pattern,
        export = PasswordValidatorCustomization.get_vnc_password_pattern
    }
}

function CustomSettings:on_import(ctx, object)
    local custom_settings = object.CustomSettings
    if not custom_settings or type(custom_settings) ~= 'table' then
        log:error('Import data(%s) is invalid', object)
        return
    end

    ctx.operation_log = { params = {} }

    for custom_setting_name, custom_setting in pairs(custom_settings) do

        local match_oem_account_conf = string.match(custom_setting_name, "(BMCSet_OEMName)")
        if match_oem_account_conf and string.match(custom_setting_name, "%d$") then
            self:import_oem_account_settings(ctx, custom_setting_name, custom_setting)
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
        if current_value == custom_value or not custom_setting_funcs.import then
            goto continue
        end

        custom_setting_funcs.import(self, ctx, custom_value)
        log:notice('Import %s successfully in customize config.', custom_setting_name)
        ::continue::
    end
    -- BMCSet_InitialPwdPrompt需要在BMCSet_initialPasswordNeedModify使能时才能开启
    if custom_settings.BMCSet_InitialPwdPrompt and custom_settings.BMCSet_InitialPwdPrompt.Value == 'on' then
        custom_settings_adapter.BMCSet_InitialPwdPrompt.import(self, ctx, true)
        log:notice('ImportBMCSet_initialPwdPrompt successfully for the second time.')
    end
    ctx.operation_log = nil
end

function CustomSettings:on_export(ctx)
    local export_data = {}
    export_data.CustomSettings = {}

    for custom_setting_name, custom_setting_funcs in pairs(custom_settings_adapter) do

        local match_oem_account_conf = string.match(custom_setting_name, "(BMCSet_OEMName)")
        if match_oem_account_conf then
            self:export_oem_account_settings(custom_setting_name, custom_setting_funcs, export_data.CustomSettings)
        elseif custom_setting_funcs.export then
            export_data.CustomSettings[custom_setting_name] = custom_setting_funcs.export(self)
        end
    end

    return export_data
end

function CustomSettings:import_oem_account_settings(ctx, custom_oem_conf_name, custom_settings)
    local custom_id = get_oem_account_id(custom_oem_conf_name)
    if custom_settings.Value ~= '' then
        log:error('custom_setting oem account name failed, %s is invalid', custom_settings.Value)
        return
    end
    local oem_account_obj = self.m_account_collection.collection[custom_id]
    -- 空定制化时从1到15都会跑一遍定制化，用户不存在时无操作，直接返回，不打印日志
    if not oem_account_obj then
        return
    end
    custom_settings_adapter['BMCSet_OEMName'].import(self, ctx, custom_id, custom_settings.Value)
end

function CustomSettings:export_oem_account_settings(custom_oem_conf_name, custom_oem_conf_funcs, custom_settings)
    local custom_id
    local custom_oem_name
    -- 用户存储id为101至115，导出时定制化项id为1至15
    for i = 1, 15 do
        custom_id = i + 100
        custom_oem_name = string.format('%s%d',custom_oem_conf_name, i)
        custom_settings[custom_oem_name] = custom_oem_conf_funcs.export(self, custom_id)
    end
end

return singleton(CustomSettings)