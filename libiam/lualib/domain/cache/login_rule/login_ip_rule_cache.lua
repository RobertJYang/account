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
local network_core = require 'network.core'
local iam_enum = require 'class.types.types'
local iam_core = require 'iam_core'

local IpRuleType = iam_enum.IpRuleType
local VERIFY_OK<const> = 0

local LoginIpRule = class()

function LoginIpRule:ctor(rule)
    self.m_rule = rule -- 规则内容
    self.m_rule_type = LoginIpRule.get_format_type(rule) -- 规则子类型：每种规则都支持多种格式
end

--- 设置规则
---@param rule string 规则
---@return string 规则
function LoginIpRule:set_rule(rule)
    self.m_rule = rule
    self.m_rule_type = self.get_format_type(rule)
end

--- 校验规则函数
---@return boolean 校验规则是否通过
function LoginIpRule:check_rule(source_ip)
    -- 字符串长度为0不校验
    if (not self.m_rule) or string.len(self.m_rule) == 0 then
        return true
    end

    -- ip格式检查，不通过返回-1
    if network_core.verify_ipv4_address(source_ip) == -1 and network_core.verify_ipv6_address(source_ip) == -1 then
        return false
    end

    if self.m_rule_type == IpRuleType.MASK or self.m_rule_type == IpRuleType.NO_MASK then
        return iam_core.is_ip_in_subnet(source_ip, self.m_rule)
    else
        return iam_core.is_ipv6_in_subnet(source_ip, self.m_rule)
    end
end

function LoginIpRule:get_rule_type()
    return self.m_rule_type
end

--- 获取规则格式类型
---@param rule string
---@return string 规则格式类型
function LoginIpRule.get_format_type(rule)
    -- 字符串长度为0不校验
    if (not rule) or string.len(rule) == 0 then
        return IpRuleType.NULL
    end

    -- 带子网掩码
    if string.match(rule, '^.*/%d+$') then
        local result = {}
        for match in string.gmatch(rule, "([^/]+)") do
            table.insert(result, match)
        end
        if #result ~= 2 then
            return IpRuleType.INVALID
        end
        local rule, mask = result[1], tonumber(result[2])
        if network_core.verify_ipv4_address(rule) == VERIFY_OK and 1 <= mask and mask <= 32 then
            return IpRuleType.MASK
        elseif  network_core.verify_ipv6_address(rule) == VERIFY_OK and 1 <= mask and mask <= 128 then
            return IpRuleType.IPV6_MASK
        end
    else --不带子网掩码
        if network_core.verify_ipv4_address(rule) == VERIFY_OK then
            return IpRuleType.NO_MASK
        elseif  network_core.verify_ipv6_address(rule) == VERIFY_OK then
            return IpRuleType.IPV6_NO_MASK
        end
    end

    return IpRuleType.INVALID
end

return LoginIpRule
