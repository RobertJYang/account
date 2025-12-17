-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local ip_rule = require 'domain.login_rule.login_ip_rule'
local mac_rule = require 'domain.login_rule.login_mac_rule'
local time_rule = require 'domain.login_rule.login_time_rule'
local account_enum = require 'class.types.types'

local IpRuleType = account_enum.IpRuleType

local LoginRuleManager = class()

function LoginRuleManager:ctor(bus, login_rule)
    self.m_bus = bus
    self.m_login_rule = login_rule
    -- 优先获取ipv4规则
    if login_rule.IpRule and login_rule.IpRule ~= "" then
        self.m_ip_rule = ip_rule.new(bus, login_rule.IpRule)
    else
        self.m_ip_rule = ip_rule.new(bus, login_rule.Ipv6Rule)
    end

    self.m_mac_rule = mac_rule.new(bus, login_rule.MacRule)
    self.m_time_rule = time_rule.new(bus, login_rule.TimeRule)
end

--- 获取规则详情
---@return table 规则详情
function LoginRuleManager:get_login_rule()
    return self.m_login_rule
end

--- 设置规则使能
---@param enabled boolean
function LoginRuleManager:set_enabled(enabled)
    self.m_login_rule.Enabled = enabled
    self.m_login_rule:save()
end

function LoginRuleManager:get_enabled()
    return self.m_login_rule.Enabled
end

--- 设置IP规则
---@param rule string
function LoginRuleManager:set_ip_rule(rule)
    self.m_ip_rule:set_rule(rule)
    local ip_type = self.m_ip_rule:get_rule_type()
    if ip_type == IpRuleType.MASK or ip_type == IpRuleType.NO_MASK then
        self.m_login_rule.IpRule = rule
        self.m_login_rule.Ipv6Rule = ""
    elseif ip_type == IpRuleType.IPV6_MASK or ip_type == IpRuleType.IPV6_NO_MASK then
        self.m_login_rule.IpRule = ""
        self.m_login_rule.Ipv6Rule = rule
    else
        self.m_login_rule.IpRule = ""
        self.m_login_rule.Ipv6Rule = ""
    end

    self.m_login_rule:save()
end

function LoginRuleManager:get_ip_rule()
    if self.m_login_rule.IpRule and self.m_login_rule.IpRule ~= "" then
        return self.m_login_rule.IpRule
    else
        return self.m_login_rule.Ipv6Rule
    end
end

--- 设置MAC规则
---@param rule string
function LoginRuleManager:set_mac_rule(rule)
    self.m_mac_rule:set_rule(rule)
    self.m_login_rule.MacRule = rule
    self.m_login_rule:save()
end

function LoginRuleManager:get_mac_rule()
    return self.m_login_rule.MacRule
end

--- 设置时间规则
---@param rule string
function LoginRuleManager:set_time_rule(rule)
    self.m_time_rule:set_rule(rule)
    self.m_login_rule.TimeRule = rule
    self.m_login_rule:save()
end

function LoginRuleManager:get_time_rule()
    return self.m_login_rule.TimeRule
end

--- 检查登录规则
---@param ip string
---@return boolean 检查结果
function LoginRuleManager:check_login_rule(ip)
    if not self.m_login_rule.Enabled then
        return true
    end

    if self.m_ip_rule:check_rule(ip) and
        self.m_mac_rule:check_rule(ip) and
        self.m_time_rule:check_rule() then
        return true
    end
    return false
end

function LoginRuleManager:data_to_line()
    return table.concat({
        tostring(self.m_login_rule.RuleId),
        tostring(self.m_login_rule.Enabled and 1 or 0),
        tostring(self.m_login_rule.TimeRule),
        tostring(self.m_login_rule.IpRule),
        tostring(self.m_login_rule.MacRule),
        tostring(self.m_login_rule.Ipv6Rule)
    }, ',')
end

return LoginRuleManager
