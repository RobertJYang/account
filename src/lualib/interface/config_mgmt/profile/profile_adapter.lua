-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 管理配置导入导出

local mc_utils = require 'mc.utils'
local custom_messages = require 'messages.custom'
local class = require 'mc.class'
local config_mgmt = require 'interface.config_mgmt.config_mgmt'
local singleton = require 'mc.singleton'
local enum = require 'class.types.types'
local operation_logger = require 'interface.operation_logger'
local AccountProfile = require 'interface.config_mgmt.profile.account_profile'
local RolePrivilegeProfile = require 'interface.config_mgmt.profile.role_privilege_profile'
local AccountServiceProfile = require 'interface.config_mgmt.profile.account_service_profile'
local LoginRuleProfile = require 'interface.config_mgmt.profile.login_rule_profile'
local PasswordValidatorProfile = require 'interface.config_mgmt.profile.password_validator_profile'
local login_rule_collection = require 'domain.login_rule.login_rule_collection'
local role_collection = require 'domain.role'
local utils = require 'infrastructure.utils'

local ProfileAdapter = class(config_mgmt)

function ProfileAdapter:ctor()
    self.m_rule_collection = login_rule_collection.get_instance()
    self.m_role_collection = role_collection.get_instance()
end

local profile_adapter = {
    User = {
        isObjectArray = true,
        instance_ids = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 },
        Id = {
            import = AccountProfile.set_account_id,
            export = AccountProfile.get_account_id
        },
        UserName = {
            import = operation_logger.proxy(function(self, ctx, account_id, value)
                AccountProfile.set_user_name(self, ctx, account_id, value)
            end, 'ChangeUserName'),
            export = AccountProfile.get_user_name
        },
        Privilege = {
            export = AccountProfile.get_role_id
        },
        UserRoleId = {
            import = operation_logger.proxy(function(self, ctx, account_id, value)
                AccountProfile.set_role_id(self, ctx, account_id, value)
            end, 'AccountRoleId'),
            export = AccountProfile.get_role_id
        },
        LoginInterface = {
            import = operation_logger.proxy(function(self, ctx, account_id, value)
                ctx.operation_log.params = { interface = table.concat(value, " ") }
                AccountProfile.set_login_interface(self, ctx, account_id, value)
            end, "LoginInterface"),
            export = AccountProfile.get_login_interface
        },
        PermitRuleIds = {
            import = operation_logger.proxy(function(self, ctx, account_id, value)
                AccountProfile.set_login_rule_ids(self, ctx, account_id, value)
            end, 'LoginRule'),
            export = AccountProfile.get_login_rule_ids
        },
        IsUserEnable = {
            export = AccountProfile.get_account_enabled
        },
        IsUserLocked = {
            export = AccountProfile.get_account_locked
        },
        SnmpPrivacyPwdInitialState = {
            export = AccountProfile.get_snmp_privacy_password_init_status
        }
    },
    UserRole = {
        isObjectArray = true,
        instance_ids = { 'NoAccess', 'CommonUser', 'Operator', 'Administrator',
            'CustomRole1', 'CustomRole2', 'CustomRole3', 'CustomRole4' },
        Id = {
            import = RolePrivilegeProfile.set_role_name,
            export = RolePrivilegeProfile.get_role_name
        },
        UserMgmt = {
            import = RolePrivilegeProfile.set_user_mgmt,
            export = RolePrivilegeProfile.get_user_mgmt
        },
        BasicSetting = {
            import = operation_logger.proxy(function(self, ctx, role_name, value)
                ctx.operation_log.params = { state = value and 'Enable' or 'Disable',
                    role_name = role_name, role = 'BasicSetting' }
                RolePrivilegeProfile.set_basic_setting(self, ctx, role_name, value)
            end, 'SetRolePrivilege'),
            export = RolePrivilegeProfile.get_basic_setting
        },
        KVMMgmt = {
            import = operation_logger.proxy(function(self, ctx, role_name, value)
                ctx.operation_log.params = { state = value and 'Enable' or 'Disable',
                    role_name = role_name, role = 'KVMMgmt' }
                    RolePrivilegeProfile.set_kvm_mgmt(self, ctx, role_name, value)
            end, 'SetRolePrivilege'),
            export = RolePrivilegeProfile.get_kvm_mgmt
        },
        VMMMgmt = {
            import = operation_logger.proxy(function(self, ctx, role_name, value)
                ctx.operation_log.params = { state = value and 'Enable' or 'Disable',
                    role_name = role_name, role = 'VMMMgmt' }
                    RolePrivilegeProfile.set_vmm_mgmt(self, ctx, role_name, value)
            end, 'SetRolePrivilege'),
            export = RolePrivilegeProfile.get_vmm_mgmt
        },
        SecurityMgmt = {
            import = operation_logger.proxy(function(self, ctx, role_name, value)
                ctx.operation_log.params = { state = value and 'Enable' or 'Disable',
                    role_name = role_name, role = 'SecurityMgmt' }
                    RolePrivilegeProfile.set_security_mgmt(self, ctx, role_name, value)
            end, 'SetRolePrivilege'),
            export = RolePrivilegeProfile.get_security_mgmt
        },
        PowerMgmt = {
            import = operation_logger.proxy(function(self, ctx, role_name, value)
                ctx.operation_log.params = { state = value and 'Enable' or 'Disable',
                    role_name = role_name, role = 'PowerMgmt' }
                    RolePrivilegeProfile.set_power_mgmt(self, ctx, role_name, value)
            end, 'SetRolePrivilege'),
            export = RolePrivilegeProfile.get_power_mgmt
        },
        DiagnoseMgmt = {
            import = operation_logger.proxy(function(self, ctx, role_name, value)
                ctx.operation_log.params = { state = value and 'Enable' or 'Disable',
                    role_name = role_name, role = 'DiagnoseMgmt' }
                    RolePrivilegeProfile.set_diagnose_mgmt(self, ctx, role_name, value)
            end, 'SetRolePrivilege'),
            export = RolePrivilegeProfile.get_diagnose_mgmt
        },
        ReadOnly = {
            import = RolePrivilegeProfile.set_read_only,
            export = RolePrivilegeProfile.get_read_only
        },
        ConfigureSelf = {
            import = RolePrivilegeProfile.set_configure_self,
            export = RolePrivilegeProfile.get_configure_self
        }
    },
    PasswdSetting = {
        EnableStrongPassword = {
            import = operation_logger.proxy(function(self, ctx, value)
                ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
                AccountServiceProfile.set_password_complexity_enable(self, ctx, value)
            end, 'PasswordComplexityEnable'),
            export = AccountServiceProfile.get_password_complexity_enable
        },
        MinPasswordLength = {
            import = operation_logger.proxy(function(self, ctx, value)
                ctx.operation_log.params = { length = value }
                AccountServiceProfile.set_password_min_length(self, ctx, value)
            end, 'MinPasswordLength'),
            export = AccountServiceProfile.get_password_min_length
        },
        LocalAccountPasswordRulePolicy = {
            import = operation_logger.proxy(function(self, ctx, value)
                PasswordValidatorProfile.set_policy(self, ctx, enum.AccountType.Local:value(), value)
            end, 'PasswordPolicy'),
            export = function(self, ctx)
                return PasswordValidatorProfile.get_policy(self, ctx, enum.AccountType.Local:value())
            end
        },
        LocalAccountPasswordPattern = {
            import = operation_logger.proxy(function(self, ctx, value)
                PasswordValidatorProfile.set_pattern(self, ctx, enum.AccountType.Local:value(), value)
            end, 'PasswordPattern'),
            export = function(self, ctx)
                return PasswordValidatorProfile.get_pattern(self, ctx, enum.AccountType.Local:value())
            end
        },
        SnmpCommunityPasswordRulePolicy = {
            import = operation_logger.proxy(function(self, ctx, value)
                PasswordValidatorProfile.set_policy(self, ctx, enum.AccountType.SnmpCommunity:value(), value)
            end, 'PasswordPolicy'),
            export = function(self, ctx)
                return PasswordValidatorProfile.get_policy(self, ctx, enum.AccountType.SnmpCommunity:value())
            end
        },
        SnmpCommunityPasswordPattern = {
            import = operation_logger.proxy(function(self, ctx, value)
                PasswordValidatorProfile.set_pattern(self, ctx, enum.AccountType.SnmpCommunity:value(), value)
            end, 'PasswordPattern'),
            export = function(self, ctx)
                return PasswordValidatorProfile.get_pattern(self, ctx, enum.AccountType.SnmpCommunity:value())
            end
        },
        VNCPasswordRulePolicy = {
            import = operation_logger.proxy(function(self, ctx, value)
                PasswordValidatorProfile.set_policy(self, ctx, enum.AccountType.VNC:value(), value)
            end, 'PasswordPolicy'),
            export = function(self, ctx)
                return PasswordValidatorProfile.get_policy(self, ctx, enum.AccountType.VNC:value())
            end
        },
        VNCPasswordPattern = {
            import = operation_logger.proxy(function(self, ctx, value)
                PasswordValidatorProfile.set_pattern(self, ctx, enum.AccountType.VNC:value(), value)
            end, 'PasswordPattern'),
            export = function(self, ctx)
                return PasswordValidatorProfile.get_pattern(self, ctx, enum.AccountType.VNC:value())
            end
        }
    },
    SecurityEnhance = {
        PwdExpiredTime = {
            import = operation_logger.proxy(function(self, ctx, value)
                ctx.operation_log.params = { max_valid_days = value }
                AccountServiceProfile.set_max_password_valid_days(self, ctx, value)
            end, 'MaxPasswordValidDays'),
            export = AccountServiceProfile.get_max_password_valid_days
        },
        MinimumPwdAge = {
            import = operation_logger.proxy(function(self, ctx, value)
                ctx.operation_log.params = { min_valid_days = value }
                AccountServiceProfile.set_min_password_valid_days(self, ctx, value)
            end, 'MinPasswordValidDays'),
            export = AccountServiceProfile.get_min_password_valid_days
        },
        UserInactTimeLimit = {
            import = operation_logger.proxy(function(self, ctx, value)
                ctx.operation_log.params = { threshold = value }
                AccountServiceProfile.set_inactive_time_threshold(self, ctx, value)
            end, 'InactiveDaysThreshold'),
            export = AccountServiceProfile.get_inactive_time_threshold
        },
        ExcludeUser = {
            import = operation_logger.proxy(function(self, ctx, value)
                AccountServiceProfile.set_emergency_account(self, ctx, value)
                if value == 0 then
                    ctx.operation_log.result = 'remove'
                end
            end, 'EmergencyLoginAccountId'),
            export = AccountServiceProfile.get_emergency_account
        },
        OldPwdCount = {
            import = operation_logger.proxy(function(self, ctx, value)
                ctx.operation_log.params = { count = value }
                AccountServiceProfile.set_history_password_count(self, ctx, value)
                if value == 0 then
                    ctx.operation_log.result = 'disable'
                end
            end, 'HistoryPasswordCount'),
            export = AccountServiceProfile.get_history_password_count
        },
        InitialPwdPrompt = {
            import = operation_logger.proxy(function(self, ctx, value)
                ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
                AccountServiceProfile.set_initial_password_prompt_enable(self, ctx, value)
            end, 'InitialPasswordPromptEnable'),
            export = AccountServiceProfile.get_initial_password_prompt_enable
        },
        InitialPasswordNeedModify = {
            import = operation_logger.proxy(function(self, ctx, value)
                ctx.operation_log.params = { state = (value and '' or 'not ') .. 'needs modify' }
                AccountServiceProfile.set_first_login_enable(self, ctx, value)
            end, 'InitialPasswordNeedModify'),
            export = AccountServiceProfile.get_first_login_enable
        },
        WeakPwdDictEnable = {
            import = operation_logger.proxy(function(self, ctx, value)
                ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
                AccountServiceProfile.set_weak_pwd_dictionary_enable(self, ctx, value)
            end, 'WeakPasswordDictionaryEnabled'),
            export = AccountServiceProfile.get_weak_pwd_dictionary_enable
        },
        LocalAccountNamePattern = {
            import = operation_logger.proxy(function(self, ctx, value)
                AccountServiceProfile.set_name_pattern(self, ctx, value)
            end, 'NamePatternChange'),
            export = AccountServiceProfile.get_name_pattern
        }
    },
    PermitRule = {
        isObjectArray = true,
        instance_ids = { 'Rule1', 'Rule2', 'Rule3' },
        Id = {
            import = LoginRuleProfile.set_rule_id,
            export = LoginRuleProfile.get_rule_id
        },
        IpRuleInfo = {
            import = operation_logger.proxy(function(self, ctx, rule_id, value)
                ctx.operation_log.params = { id = rule_id, ip_info = tostring(value) }
                LoginRuleProfile.set_ip_rule(self, ctx, rule_id, value)
            end, 'IpRule'),
            export = LoginRuleProfile.get_ip_rule
        },
        MacRuleInfo = {
            import = operation_logger.proxy(function(self, ctx, rule_id, value)
                ctx.operation_log.params = { id = rule_id, mac_info = tostring(value) }
                LoginRuleProfile.set_mac_rule(self, ctx, rule_id, value)
            end, 'MacRule'),
            export = LoginRuleProfile.get_mac_rule
        },
        TimeRuleInfo = {
            import = operation_logger.proxy(function(self, ctx, rule_id, value)
                ctx.operation_log.params = { id = rule_id, time_info = tostring(value) }
                LoginRuleProfile.set_time_rule(self, ctx, rule_id, value)
            end, 'TimeRule'),
            export = LoginRuleProfile.get_time_rule
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
    LoginInterface = utils.cover_interface_str_to_num,
    PermitRuleIds = utils.covert_login_rule_ids_str_to_num
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

function ProfileAdapter:import_instances(ctx, class_name, instance_id, property_name, property_value)
    local ok = pcall(function()
        if not (profile_adapter[class_name][property_name] and profile_adapter[class_name][property_name].import) then
            return
        end
        local current_value = profile_adapter[class_name][property_name].export(self, instance_id)
        if verify_property_not_change(property_name, property_value, current_value) then
            return
        end
        profile_adapter[class_name][property_name].import(self, ctx, instance_id, property_value)
    end)
    if not ok then
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

function ProfileAdapter:import_handle(ctx, class_name, class_data)
    if class_name == "User" then
        class_data = AccountProfile.import_account_precheck(self, ctx, class_data)
    end
    if is_object_array(class_data) then
        for _, instance in ipairs(class_data) do
            local instance_id = instance.Id.Value
            local ok = pcall(function()
                profile_adapter[class_name].Id.import(self, ctx, instance_id)
            end)
            if not ok then
                local err_msg = string.format("/%s/%s/%s", class_name, instance_id, 'Id')
                error(custom_messages.CollectingConfigurationErrorDesc(err_msg))
            end
            for property_name, property_value in pairs(instance) do
                self:import_instances(ctx, class_name, instance_id, property_name, property_value.Value)
            end
        end
    else
        for property_name, property_value in pairs(class_data) do
            self:import_property(ctx, class_name, property_name, property_value.Value)
        end
    end
end

function ProfileAdapter:on_import(ctx, object)
    ctx.operation_log = { params = {} }

    for class_name, class_data in pairs(object) do
        if not profile_adapter[class_name] then
            goto continue
        end
        self:import_handle(ctx, class_name, class_data)
        ::continue::
    end

    ctx.operation_log = nil
end

function ProfileAdapter:export_instances(export_data, class_name, class_data, instance_id)
    if not class_data.Id.export(self, instance_id) then
        goto continue
    end
    local instance = {}
    for property_name, property in pairs(class_data) do
        if type(property) == 'table' and property.export then
            instance[property_name] = property.export(self, instance_id)
        end
    end
    export_data[class_name][#export_data[class_name] + 1] = instance
    ::continue::
end

function ProfileAdapter:on_export(ctx)
    local export_data = {}

    for class_name, class_data in pairs(profile_adapter) do
        export_data[class_name] = {}
        if class_data.isObjectArray then
            for _, instance_id in ipairs(class_data.instance_ids) do
                self:export_instances(export_data, class_name, class_data, instance_id)
            end
        else
            for property_name, property in pairs(class_data) do
                export_data[class_name][property_name] = property.export(self)
            end
        end
    end

    return export_data
end

return singleton(ProfileAdapter)
