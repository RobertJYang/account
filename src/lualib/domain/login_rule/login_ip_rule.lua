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
local log = require 'mc.logging'
local network_core = require 'network.core'
local utils_core = require 'utils.core'
local base_msg = require 'messages.base'
local account_enum = require 'class.types.types'
local account_core = require 'account_core'

local IpRuleType = account_enum.IpRuleType
local VERIFY_OK<const> = 0

local LoginIpRule = class()

function LoginIpRule:ctor(bus, rule)
    if not LoginIpRule.check_format(rule) then
        log:error('The rule does not meet the format requirements')
        error(base_msg.PropertyValueFormatError(rule, 'IP'))
    end

    self.m_bus = bus
    self.m_rule = rule -- 规则内容
    self.m_rule_type = LoginIpRule.get_format_type(rule) -- 规则子类型：每种规则都支持多种格式
end

--- 设置规则
---@param rule string 规则
---@return string 规则
function LoginIpRule:set_rule(rule)
    if not LoginIpRule.check_format(rule) then
        log:error('The rule does not meet the format requirements')
        error(base_msg.PropertyValueFormatError(rule, 'IP'))
    end

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
        return account_core.is_ip_in_subnet(source_ip, self.m_rule)
    else
        return account_core.is_ipv6_in_subnet(source_ip, self.m_rule)
    end
end

--- 检查IP规则合法性，格式如下：
---@param rule string 规则
---@return boolean IP规则是否合法
function LoginIpRule.check_format(rule)
    -- 字符串长度为0不校验
    if (not rule) or string.len(rule) == 0 then
        return true
    end
    -- IP规则最长50个字符
    if string.len(rule) > 50 then
        return false
    end

    local format_type = LoginIpRule.get_format_type(rule)
    if format_type == IpRuleType.INVALID then
        return false
    end

    return true
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

--- 将Byte数字类型转换为二进制字符串
---@param byte number
---@return string 二进制字符串
function LoginIpRule.convert_byte_to_binary(byte)
    local binary = {}
    for i = 7, 0, -1 do
        -- 每次迭代增加1位，迭代除2获取二进制
        binary[#binary + 1] = math.floor(byte / 2 ^ i)
        byte = byte % 2 ^ i -- 余2获取下一次迭代二进制
    end
    return table.concat(binary)
end

return LoginIpRule
