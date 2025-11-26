-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local ip_rule = require 'domain.cache.login_rule.login_ip_rule_cache'
local mac_rule = require 'domain.cache.login_rule.login_mac_rule_cache'
local time_rule = require 'domain.cache.login_rule.login_time_rule_cache'

local LoginRuleManager = class()

function LoginRuleManager:ctor(login_rule)
    self.m_login_rule = login_rule
    self.m_ip_rule = ip_rule.new(login_rule.IpRule)
    self.m_mac_rule = mac_rule.new(login_rule.MacRule)
    self.m_time_rule = time_rule.new(login_rule.TimeRule)
    self.is_flush = login_rule.is_flush
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
end

function LoginRuleManager:get_enabled()
    return self.m_login_rule.Enabled
end

--- 设置IP规则
---@param rule string
function LoginRuleManager:set_ip_rule(rule)
    self.m_ip_rule:set_rule(rule)
end

function LoginRuleManager:get_ip_rule()
    return self.m_login_rule.IpRule
end

--- 设置MAC规则
---@param rule string
function LoginRuleManager:set_mac_rule(rule)
    self.m_mac_rule:set_rule(rule)
    self.m_login_rule.MacRule = rule
end

function LoginRuleManager:get_mac_rule()
    return self.m_login_rule.MacRule
end

--- 设置时间规则
---@param rule string
function LoginRuleManager:set_time_rule(rule)
    self.m_time_rule:set_rule(rule)
    self.m_login_rule.TimeRule = rule
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


return LoginRuleManager
