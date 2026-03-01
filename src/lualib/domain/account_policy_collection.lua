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
local local_account_policy = require 'domain.account_policies.local_account_policy'
local oem_account_policy = require 'domain.account_policies.oem_account_policy'
local inter_chassis_account_policy = require 'domain.account_policies.inter_chassis_account_policy'
local core = require 'account_core'
local utils = require 'infrastructure.utils'

local AccountPolicyCollection = class()

local account_type_map = {
    [enum.AccountType.Local:value()] = {
        name = 'LocalAccount',
        obj  = local_account_policy
    },
    [enum.AccountType.OEM:value()] = {
        name = 'OEMAccount',
        obj  = oem_account_policy
    },
    [enum.AccountType.InterChassis:value()] = {
        name = 'InterChassis',
        obj  = inter_chassis_account_policy
    }
}

function AccountPolicyCollection:ctor(db, global_account_config)
    self.db = db
    self.m_account_config = global_account_config

    local policy_collection = db:select(db.AccountPolicyDB):fold(function(policy, acc)
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

function AccountPolicyCollection:get_policy(account_type)
    return self.collection[account_type]
end

function AccountPolicyCollection:get_allowed_login_interfaces(account_type)
    return self.collection[account_type]:get_allowed_login_interfaces()
end

function AccountPolicyCollection:set_allowed_login_interfaces(account_type, interface_num)
    self.collection[account_type]:set_allowed_login_interfaces(interface_num)
    self.m_config_changed:emit(account_type, 'AllowedLoginInterfaces',
        utils.convert_num_to_interface_str(interface_num, true))
end

function AccountPolicyCollection:get_name_pattern(account_type)
    return self.collection[account_type]:get_name_pattern()
end

function AccountPolicyCollection:set_name_pattern(account_type, pattern)
    self.collection[account_type]:set_name_pattern(pattern)
    self.m_config_changed:emit(account_type, 'NamePattern', pattern)
end

function AccountPolicyCollection:check_user_name(account_type, user_name)
    return self.collection[account_type]:check_user_name(user_name)
end

function AccountPolicyCollection:check_login_interface_is_allowed(account_type, login_interface)
    if core.is_manufacture_mode() then
        log:notice("Skip checking allowed login interface in manufacture mode")
        return true
    end
    return self.collection[account_type]:check_login_interface_is_allowed(login_interface)
end

function AccountPolicyCollection:set_visible(ctx, account_type, value)
    if not self.collection[account_type] then
        error(base_msg.InternalError())
    end
    ctx.operation_log.params.account_type = account_type_map[account_type].name
    ctx.operation_log.params.Status = tostring(value)
    self.collection[account_type]:set_visible(value)
    self.m_config_changed:emit(account_type, 'Visible', value)
end

function AccountPolicyCollection:get_visible(account_type)
    if not self.collection[account_type] then
        error(base_msg.InternalError())
    end
    return self.collection[account_type]:get_visible()
end

function AccountPolicyCollection:set_deletable(ctx, account_type, value)
    if not self.collection[account_type] then
        error(base_msg.InternalError())
    end
    ctx.operation_log.params.account_type = account_type_map[account_type].name
    ctx.operation_log.params.Status = tostring(value)
    self.collection[account_type]:set_deletable(value)
    self.m_config_changed:emit(account_type, 'Deletable', value)
end

function AccountPolicyCollection:get_deletable(account_type)
    if not self.collection[account_type] then
        error(base_msg.InternalError())
    end
    return self.collection[account_type]:get_deletable()
end

function AccountPolicyCollection:get_online_deletable(account_type)
    if not self.collection[account_type] then
        log:debug('can not get online deletable, account_type:%s', account_type)
        return true
    end
    return self.collection[account_type]:get_online_deletable()
end

function AccountPolicyCollection:set_online_deletable(account_type, value)
    self.collection[account_type]:set_online_deletable(value)
    self.m_config_changed:emit(account_type, 'OnlineDeletable', value)
end

function AccountPolicyCollection:flush_inter_chassis_policy_by_sr(inter_chassis_config)
    if inter_chassis_config.Visible == nil then
        return
    end
    local account_type = enum.AccountType.InterChassis:value()
    local inter_chassis_policy = self.collection[account_type]
    inter_chassis_policy.data.Visible = inter_chassis_config.Visible
    inter_chassis_policy.data:save()
    self.m_config_changed:emit(account_type, 'Visible', inter_chassis_policy.data.Visible)
end

return singleton(AccountPolicyCollection)