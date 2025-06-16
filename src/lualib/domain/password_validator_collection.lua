-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local signal = require 'mc.signal'
local class = require 'mc.class'
local log = require 'mc.logging'
local base_msg = require 'messages.base'
local enum = require 'class.types.types'
local local_password_validator = require 'domain.password_validator.local_password_validator'
local snmp_community_password_validator = require 'domain.password_validator.snmp_community_password_validator'
local vnc_password_validator = require 'domain.password_validator.vnc_password_validator'

local PasswordValidatorCollection = class()

local account_type_map = {
    [enum.AccountType.Local:value()] = {
        name = 'LocalAccount',
        obj  = local_password_validator
    },
    [enum.AccountType.VNC:value()] = {
        name = 'VNC',
        obj  = vnc_password_validator
    },
    [enum.AccountType.SnmpCommunity:value()] = {
        name = 'SnmpCommunity',
        obj  = snmp_community_password_validator
    }
}

function PasswordValidatorCollection:ctor(db, global_account_config)
    self.db = db
    self.m_account_config = global_account_config

    local policy_collection = db:select(db.PasswordPolicy):fold(function(policy, acc)
        if not account_type_map[policy.AccountType] then
            log:error("invalid policy data, account_type(%d)", policy.AccountType)
            policy:delete()
            return acc
        end
        local entity = account_type_map[policy.AccountType].obj.new(policy, self.m_account_config)
        acc[policy.AccountType] = entity
        return acc
    end, {})
    self.collection = policy_collection
    self.m_config_changed = signal.new()
end

function PasswordValidatorCollection:get_validator(account_type)
    return self.collection[account_type]
end

function PasswordValidatorCollection:set_policy(ctx, account_type, value)
    if not self.collection[account_type] then
        error(base_msg.InternalError())
    end
    ctx.operation_log.params.account_type = account_type_map[account_type].name
    if value < 1 or value > 3 then
        error(base_msg.PropertyValueNotInList(value, "PasswordRulePolicy"))
    end
    ctx.operation_log.params.policy = tostring(enum.PasswordRulePolicy.new(value))
    self.collection[account_type]:set_policy(value)
end

function PasswordValidatorCollection:get_policy(account_type)
    if not self.collection[account_type] then
        error(base_msg.InternalError())
    end
    return self.collection[account_type]:get_policy()
end

function PasswordValidatorCollection:set_pattern(ctx, account_type, value)
    if not self.collection[account_type] then
        error(base_msg.InternalError())
    end
    ctx.operation_log.params = {account_type = account_type_map[account_type].name}
    self.collection[account_type]:set_pattern(value)
end

function PasswordValidatorCollection:get_pattern(account_type)
    if not self.collection[account_type] then
        error(base_msg.InternalError())
    end
    return self.collection[account_type]:get_pattern()
end

return singleton(PasswordValidatorCollection)