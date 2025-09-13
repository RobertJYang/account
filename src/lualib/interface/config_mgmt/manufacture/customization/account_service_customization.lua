-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 定制化操作时用户公共服务相关项
local utils = require 'infrastructure.utils'
local base_msg = require 'messages.base'
local log = require 'mc.logging'
local config = require 'common_config'
local enum = require 'class.types.types'

local AccountServiceCustomization = {}

local ENABLED_IMPORT_MAP = {
    ['on'] = true,
    ['off'] = false
}

local ENABLED_EXPORT_MAP = {
    [true] = 'on',
    [false] = 'off'
}

local VALUE_BOOLEN_MAP = {
    [0] = false,
    [1] = true
}

local BOOLEN_VALUE_MAP = {
    [true] = 1,
    [false] = 0
}

function AccountServiceCustomization.convert_password_complexity_enable(custom_settings)
    return ENABLED_IMPORT_MAP[custom_settings['BMCSet_UserPasswdComplexityCheckEnable'].Value]
end

function AccountServiceCustomization.set_password_complexity_enable(self, ctx, value)
    self.m_account_config:set_password_complexity_enable(value)
    self.m_account_service.m_config_changed:emit('PasswordComplexityEnable', value)
end

function AccountServiceCustomization.get_password_complexity_enable(self)
    local enabled = self.m_account_config:get_password_complexity_enable()
    return ENABLED_EXPORT_MAP[enabled]
end

function AccountServiceCustomization.set_password_min_length(self, ctx, value)
    self.m_account_config:set_password_min_length(value)
    self.m_account_service.m_config_changed:emit('MinPasswordLength', value)
end

function AccountServiceCustomization.get_password_min_length(self)
    return self.m_account_config:get_password_min_length()
end

function AccountServiceCustomization.set_max_password_valid_days(self, ctx, value)
    self.m_account_service:set_max_password_valid_days(value)
    self.m_account_service.m_config_changed:emit('MaxPasswordValidDays', value)
end

function AccountServiceCustomization.get_max_password_valid_days(self)
    return self.m_account_config:get_max_password_valid_days()
end

function AccountServiceCustomization.set_min_password_valid_days(self, ctx, value)
    self.m_account_config:set_min_password_valid_days(value)
    self.m_account_service.m_config_changed:emit('MinPasswordValidDays', value)
end

function AccountServiceCustomization.get_min_password_valid_days(self)
    return self.m_account_config:get_min_password_valid_days()
end

function AccountServiceCustomization.set_inactive_time_threshold(self, ctx, value)
    self.m_account_service:set_inactive_time_threshold(value)
    self.m_account_service.m_config_changed:emit('InactiveDaysThreshold', value)
end

function AccountServiceCustomization.get_inactive_time_threshold(self)
    return self.m_account_config:get_inactive_time_threshold()
end

function AccountServiceCustomization.set_emergency_account(self, ctx, value)
    self.m_account_service:set_emergency_account(ctx, value)
    self.m_account_service.m_config_changed:emit('EmergencyLoginAccountId', value)
end

function AccountServiceCustomization.get_emergency_account(self)
    return self.m_account_config:get_emergency_account()
end

function AccountServiceCustomization.set_snmp_v3_trap_account(self, ctx, value)
    self.m_account_service:set_snmp_v3_trap_account(ctx, value)
    self.m_account_service.m_config_changed:emit('SNMPv3TrapAccountId', value)
end

function AccountServiceCustomization.get_snmp_v3_trap_account(self)
    return self.m_account_config:get_snmp_v3_trap_account_id()
end

function AccountServiceCustomization.set_history_password_count(self, ctx, value)
    self.m_account_service:set_history_password_count(value)
    self.m_account_service.m_config_changed:emit('HistoryPasswordCount', value)
end

function AccountServiceCustomization.get_history_password_count(self)
    return self.m_account_config:get_history_password_count()
end

function AccountServiceCustomization.convert_initial_password_prompt_enable(custom_settings)
    return ENABLED_IMPORT_MAP[custom_settings['BMCSet_InitialPwdPrompt'].Value]
end

function AccountServiceCustomization.set_initial_password_prompt_enable(self, ctx, value)
    self.m_account_service:set_initial_password_prompt_enable(value)
    self.m_account_service.m_config_changed:emit('InitialPasswordPromptEnable', value)
end

function AccountServiceCustomization.get_initial_password_prompt_enable(self)
    local enabled = self.m_account_config:get_initial_password_prompt_enable()
    return ENABLED_EXPORT_MAP[enabled]
end

function AccountServiceCustomization.set_first_login_enable(self, ctx, value)
    local enabled = ENABLED_IMPORT_MAP[value]
    self.m_account_service:set_initial_password_need_modify(enabled)
    self.m_account_service.m_config_changed:emit('InitialPasswordNeedModify', enabled)
end

function AccountServiceCustomization.get_first_login_enable(self)
    local enabled = self.m_account_config:get_initial_password_need_modify()
    return ENABLED_EXPORT_MAP[enabled]
end

function AccountServiceCustomization.convert_weak_pwd_dictionary_enable(custom_settings)
    return ENABLED_IMPORT_MAP[custom_settings['BMCSet_WeakPasswdDictionaryCheck'].Value]
end

function AccountServiceCustomization.set_weak_pwd_dictionary_enable(self, ctx, value)
    self.m_account_config:set_weak_pwd_dictionary_enable(value)
    self.m_account_service.m_config_changed:emit('WeakPasswordDictionaryEnabled', value)
end

function AccountServiceCustomization.get_weak_pwd_dictionary_enable(self)
    local enabled = self.m_account_config:get_weak_pwd_dictionary_enable()
    return ENABLED_EXPORT_MAP[enabled]
end

function AccountServiceCustomization.set_local_allowed_login_interfaces(self, ctx, value)
    -- 定制接口值含有不支持的接口则需要报错
    if value & config.DEFAULT_INTERFACES ~= value then
        log:error('set allowed login interfaces failed, interfaces num value : %d', value)
        error(base_msg.PropertyValueNotInList(value, "LoginInterface"))
    end
    local login_interfaces_str = utils.convert_num_to_interface_str(value, true)
    ctx.operation_log.params = { interfaces = table.concat(login_interfaces_str, ', ') }
    self.m_account_policy_collection:set_allowed_login_interfaces(enum.AccountType.Local:value(), value)
end

function AccountServiceCustomization.get_local_allowed_login_interfaces(self)
    local account_type = enum.AccountType.Local:value()
    return self.m_account_policy_collection:get_allowed_login_interfaces(account_type)
end

function AccountServiceCustomization.set_long_community_enable(self, ctx, value)
    self.m_account_config:set_long_community_enabled(value)
    self.m_account_service_ipmi.m_update_config:emit('LongCommunityEnabled', value)
end

-- 定制化长密码使能用1表示启用，0表示关闭
function AccountServiceCustomization.get_long_community_enable(self)
    local enabled = self.m_account_config:get_long_community_enabled()
    return BOOLEN_VALUE_MAP[enabled]
end

function AccountServiceCustomization.convert_long_community_enable(custom_settings)
    return VALUE_BOOLEN_MAP[custom_settings['BMCSet_LongPasswordEnable'].Value]
end

return AccountServiceCustomization