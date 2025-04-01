-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local context = require 'mc.context'
local base_msg = require 'messages.base'
local service = require 'account.service'
local enum = require 'class.types.types'
local operation_logger = require 'interface.operation_logger'

local c_object = require 'mc.orm.object'
local password_validator_obj = c_object('PasswordPolicy')

-- ORM会尝试调用create_mdb_object将模型类上库
-- 手动实现用户的各模型类create_mdb_object, 避免刷日志
function password_validator_obj.create_mdb_object(value)
    return value
end

local INTERFACE_password_validator = 'bmc.kepler.AccountService.PasswordPolicy'

local PasswordValidatorMdb = class()

function PasswordValidatorMdb:ctor(password_validator_collection)
    self.m_policy_collection = password_validator_collection
    self.m_mdb_policys = {}
end

function PasswordValidatorMdb:init()
    for _, policy in pairs(self.m_policy_collection.collection) do
        self:new_policy_to_mdb_tree(policy:get_obj())
    end

    self.m_policy_collection.m_config_changed:on(function(...)
        self:policy_mdb_update(...)
    end)
end

-- 属性监听钩子
PasswordValidatorMdb.watch_property_hook = {
    Policy = operation_logger.proxy(function(self, ctx, account_type, value)
        self.m_policy_collection:set_policy(ctx, account_type, value)
    end, 'PasswordPolicy'),
    Pattern = operation_logger.proxy(function(self, ctx, account_type, value)
        self.m_policy_collection:set_pattern(ctx, account_type, value)
    end, 'PasswordPattern')
}

function PasswordValidatorMdb:watch_policy_property(policy, account_type)
    policy[INTERFACE_password_validator].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the property(%s), sender is nil', name)
            return true
        end

        if not self.watch_property_hook[name] then
            log:error('change the property(%s), invalid', name)
            error(base_msg.InternalError())
        end
        log:info('change the property(%s)', name)
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_property_hook[name](self, ctx, account_type, value)
        return true
    end)
end

function PasswordValidatorMdb:new_policy_to_mdb_tree(policy_info)
    local account_type_name = tostring(enum.AccountType.new(policy_info.AccountType))
    local cur_policy = service:CreatePasswordPolicy(account_type_name, function(policy)
        policy.Policy  = policy_info.Policy
        policy.Pattern = policy_info.Pattern
        self:watch_policy_property(policy, policy_info.AccountType)
    end)
    self.m_mdb_policys[policy_info.AccountType] = cur_policy
end

function PasswordValidatorMdb:policy_mdb_update(account_type, property, value)
    if self.m_mdb_policys[account_type] == nil then
        return
    end
    self.m_mdb_policys[account_type][INTERFACE_password_validator][property] = value
end

return singleton(PasswordValidatorMdb)
