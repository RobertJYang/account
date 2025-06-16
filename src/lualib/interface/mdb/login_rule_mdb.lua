-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local context = require 'mc.context'
local class = require 'mc.class'
local base_msg = require 'messages.base'
local service = require 'account.service'
local operation_logger = require 'interface.operation_logger'

local INTERFACE_RULE = 'bmc.kepler.AccountService.Rule'

local login_rule_mdb = class()

function login_rule_mdb:ctor(rule_collection)
    self.m_rule_collection = rule_collection
    self.m_rules = {}
end

function login_rule_mdb:regist_rule_signals()
    self.m_create_unregist_handle = self.m_rule_collection.m_login_rule_create:on(function(...)
        self:create_rule_mdb_tree(...)
    end)
    self.m_update_unregist_handle = self.m_rule_collection.m_login_rule_update:on(function(...)
        self:update_rule_mdb_tree(...)
    end)
end

function login_rule_mdb:create_rule_mdb_tree(login_rule_info)
    local rule = service:CreateRule(tostring(login_rule_info.RuleId), function(rule)
        rule.Enabled = login_rule_info.Enabled
        -- 优先获取ipv4规则
        if login_rule_info.IpRule and login_rule_info.IpRule ~= "" then
            rule.IpRule = login_rule_info.IpRule
        else
            rule.IpRule = login_rule_info.Ipv6Rule
        end
        rule.MacRule = login_rule_info.MacRule
        rule.TimeRule = login_rule_info.TimeRule
        self:watch_property(rule, login_rule_info.RuleId)
    end)
    self.m_rules[login_rule_info.RuleId] = rule
end

function login_rule_mdb:update_rule_mdb_tree(rule_id, property, value)
    if not self.m_rules[rule_id] then
        return
    end

    self.m_rules[rule_id][property] = value
end

-- 属性监听钩子
login_rule_mdb.watch_property_hook = {
    Enabled = operation_logger.proxy(function(self, ctx, rule_id, value)
        ctx.operation_log.params = { id = rule_id, state = value and 'Enable' or 'Disable' }
        self.m_rule_collection:set_enable(rule_id, value)
    end, 'RuleEnabled'),
    IpRule = operation_logger.proxy(function(self, ctx, rule_id, value)
        ctx.operation_log.params = { id = rule_id, ip_info = tostring(value) }
        self.m_rule_collection:set_ip_rule(rule_id, value)
    end, 'IpRule'),
    MacRule = operation_logger.proxy(function(self, ctx, rule_id, value)
        ctx.operation_log.params = { id = rule_id, mac_info = tostring(value) }
        self.m_rule_collection:set_mac_rule(rule_id, value)
    end, 'MacRule'),
    TimeRule = operation_logger.proxy(function(self, ctx, rule_id, value)
        ctx.operation_log.params = { id = rule_id, time_info = tostring(value) }
        self.m_rule_collection:set_time_rule(rule_id, value)
    end, 'TimeRule')
}

function login_rule_mdb:watch_property(rule, rule_id)
    rule[INTERFACE_RULE].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the property(%s) to value(%s), sender is nil', name, tostring(value))
            return true
        end

        if not self.watch_property_hook[name] then
            log:error('change the property(%s) to value(%s), invalid', name, tostring(value))
            error(base_msg.InternalError())
        end

        log:info('change the property(%s) to value(%s)', name, tostring(value))
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_property_hook[name](self, ctx, rule_id, value)
        return true
    end)
end

return singleton(login_rule_mdb)
