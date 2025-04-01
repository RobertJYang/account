-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 定制化操作时密码校验服务相关项
local enum = require 'class.types.types'
local base_msg = require 'messages.base'

local PasswordValidatorCustomization = {}

local POLICY_TO_NUM_MAP = {
    ['Default']    = 1,
    ['Customized'] = 2,
    ['Hybrid']     = 3
}

local NUM_TO_POLICY_MAP = {
    [1] = 'Default',
    [2] = 'Customized',
    [3] = 'Hybrid'
}

function PasswordValidatorCustomization.set_local_account_password_policy(self, ctx, value)
    local value_num = POLICY_TO_NUM_MAP[value]
    if not value_num then
        error(base_msg.PropertyValueNotInList(value, "PasswordRulePolicy"))
    end
    self.m_password_validator_collection:set_policy(ctx, enum.AccountType.Local:value(), value_num)
    self.m_password_validator_collection.m_config_changed:emit(enum.AccountType.Local:value(), 'Policy', value_num)
end

function PasswordValidatorCustomization.get_local_account_password_policy(self, ctx)
    local value = self.m_password_validator_collection:get_policy(enum.AccountType.Local:value())
    return NUM_TO_POLICY_MAP[value]
end

function PasswordValidatorCustomization.set_local_account_password_pattern(self, ctx, value)
    self.m_password_validator_collection:set_pattern(ctx, enum.AccountType.Local:value(), value)
    self.m_password_validator_collection.m_config_changed:emit(enum.AccountType.Local:value(), 'Pattern', value)
end

function PasswordValidatorCustomization.get_local_account_password_pattern(self, ctx)
    return self.m_password_validator_collection:get_pattern(enum.AccountType.Local:value())
end

function PasswordValidatorCustomization.set_snmp_community_policy(self, ctx, value)
    local value_num = POLICY_TO_NUM_MAP[value]
    if not value_num then
        error(base_msg.PropertyValueNotInList(value, "PasswordRulePolicy"))
    end
    self.m_password_validator_collection:set_policy(ctx, enum.AccountType.SnmpCommunity:value(), value_num)
    self.m_password_validator_collection.m_config_changed:emit(enum.AccountType.SnmpCommunity:value(), 'Policy',
        value_num)
end

function PasswordValidatorCustomization.get_snmp_community_policy(self, ctx)
    local value = self.m_password_validator_collection:get_policy(enum.AccountType.SnmpCommunity:value())
    return NUM_TO_POLICY_MAP[value]
end

function PasswordValidatorCustomization.set_snmp_community_pattern(self, ctx, value)
    self.m_password_validator_collection:set_pattern(ctx, enum.AccountType.SnmpCommunity:value(), value)
    self.m_password_validator_collection.m_config_changed:emit(enum.AccountType.SnmpCommunity:value(), 'Pattern',
        value)
end

function PasswordValidatorCustomization.get_snmp_community_pattern(self, ctx)
    return self.m_password_validator_collection:get_pattern(enum.AccountType.SnmpCommunity:value())
end

function PasswordValidatorCustomization.set_vnc_password_policy(self, ctx, value)
    local value_num = POLICY_TO_NUM_MAP[value]
    if not value_num then
        error(base_msg.PropertyValueNotInList(value, "PasswordRulePolicy"))
    end
    self.m_password_validator_collection:set_policy(ctx, enum.AccountType.VNC:value(), value_num)
    self.m_password_validator_collection.m_config_changed:emit(enum.AccountType.VNC:value(), 'Policy', value_num)
end

function PasswordValidatorCustomization.get_vnc_password_policy(self, ctx)
    local value = self.m_password_validator_collection:get_policy(enum.AccountType.VNC:value())
    return NUM_TO_POLICY_MAP[value]
end

function PasswordValidatorCustomization.set_vnc_password_pattern(self, ctx, value)
    self.m_password_validator_collection:set_pattern(ctx, enum.AccountType.VNC:value(), value)
    self.m_password_validator_collection.m_config_changed:emit(enum.AccountType.VNC:value(), 'Pattern', value)
end

function PasswordValidatorCustomization.get_vnc_password_pattern(self, ctx)
    return self.m_password_validator_collection:get_pattern(enum.AccountType.VNC:value())
end

return PasswordValidatorCustomization