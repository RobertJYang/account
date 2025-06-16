-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
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
local utils = require 'infrastructure.utils'

local c_object = require 'mc.orm.object'
local account_policy_obj = c_object('AccountPolicyDB')

-- ORM会尝试调用create_mdb_object将模型类上库
-- 手动实现用户的各模型类create_mdb_object, 避免刷日志
function account_policy_obj.create_mdb_object(value)
    return value
end

local INTERFACE_ACCOUNT_POLICY = 'bmc.kepler.AccountService.AccountPolicy'

local AccountPolicyMdb = class()

local account_type_name_map = {
    [enum.AccountType.Local:value()] = 'Local',
    [enum.AccountType.OEM:value()] = 'OemAccount'
}

function AccountPolicyMdb:ctor(account_policy_collection)
    self.m_policy_collection = account_policy_collection
    self.m_mdb_policys = {}
end

function AccountPolicyMdb:init()
    for _, policy in pairs(self.m_policy_collection.collection) do
        self:new_policy_to_mdb_tree(policy:get_obj())
    end

    self.m_policy_collection.m_config_changed:on(function(...)
        self:policy_mdb_update(...)
    end)
end

-- 属性监听钩子
AccountPolicyMdb.watch_property_hook = {
    NamePattern = operation_logger.proxy(function(self, ctx, account_type, value)
        self.m_policy_collection:set_name_pattern(account_type, value)
    end, 'NamePatternChange'),
    AllowedLoginInterfaces = operation_logger.proxy(function(self, ctx, account_type, value)
        ctx.operation_log.params = { interfaces = table.concat(value, ', ') }
        local interface_num = utils.cover_interface_str_to_num(value)
        self.m_policy_collection:set_allowed_login_interfaces(account_type, interface_num)
    end, 'SetAllowedLoginInterfaces'),
    Visible = operation_logger.proxy(function(self, ctx, account_type, value)
        self.m_policy_collection:set_visible(ctx, account_type, value)
    end, 'VisibleChange'),
    Deletable = operation_logger.proxy(function(self, ctx, account_type, value)
        self.m_policy_collection:set_deletable(ctx, account_type, value)
    end, 'DeletableChange'),
}

function AccountPolicyMdb:watch_policy_property(policy, account_type)
    policy[INTERFACE_ACCOUNT_POLICY].property_before_change:on(function(name, value, sender)
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

function AccountPolicyMdb:new_policy_to_mdb_tree(policy_info)
    local account_type_name = account_type_name_map[policy_info.AccountType]
    local cur_policy = service:CreateAccountPolicy(account_type_name, function(policy)
        policy.NamePattern = policy_info.NamePattern
        policy.AllowedLoginInterfaces = utils.convert_num_to_interface_str(policy_info.AllowedLoginInterfaces, true)
        policy.Visible  = policy_info.Visible
        policy.Deletable = policy_info.Deletable
        self:watch_policy_property(policy, policy_info.AccountType)
    end)
    self.m_mdb_policys[policy_info.AccountType] = cur_policy
end

function AccountPolicyMdb:policy_mdb_update(account_type, property, value)
    if self.m_mdb_policys[account_type] == nil then
        return
    end
    self.m_mdb_policys[account_type][INTERFACE_ACCOUNT_POLICY][property] = value
end

return singleton(AccountPolicyMdb)
