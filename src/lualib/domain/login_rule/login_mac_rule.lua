-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local log = require 'mc.logging'
local network_core = require 'network.core'
local base_msg = require 'messages.base'
local client = require 'account.client'
local core = require 'account_core'

require 'bmc_network.json_types.EthernetInterfaces'

local PATH_ETHERNET<const> = '/bmc/kepler/Managers/1/EthernetInterfaces'

local mac_rule = class()

function mac_rule:ctor(bus, rule)
    if not mac_rule.check_format(rule) then
        log:error('The rule does not meet the format requirements')
        error(base_msg.PropertyValueFormatError(rule, 'Mac'))
    end

    self.m_bus = bus
    self.m_rule = rule -- 规则内容
    self.m_rule_type = mac_rule.get_format_type(rule) -- 规则子类型：每种规则都支持多种格式
end

-- MAC规则格式映射表
mac_rule.rule_format_type_map = {
    INTEGRITY = {
        regexp = '(%x+):(%x+):(%x+):(%x+):(%x+):(%x+)',
        check_format = function(...) return mac_rule.check_format_intergrity(...) end,
        check_rule = function(...) return mac_rule.check_rule_common(...) end
    },
    THREE_SEGMENT = {
        regexp = '(%x+):(%x+):(%x+)',
        check_format = function(...) return mac_rule.check_format_three_segment(...) end,
        check_rule = function(...) return mac_rule.check_rule_common(...) end
    }
}

--- 获取EthName
---@return string
local function get_eth_name()
    local objs = client:GetEthernetInterfacesObjects()
    -- 一般情况下，只有一个对象
    for path, obj in pairs(objs) do
        if path == PATH_ETHERNET then
            return obj.EthName
        end
    end
    log:error('get eth name fail.')
    error(base_msg.InternalError())
end

--- 设置规则
---@param rule string 规则
---@return string 规则
function mac_rule:set_rule(rule)
    if not mac_rule.check_format(rule) then
        log:error('The rule does not meet the format requirements')
        error(base_msg.PropertyValueFormatError(rule, 'Mac'))
    end

    self.m_rule = rule
    self.m_rule_type = self.get_format_type(rule)
end

--- 校验规则函数
---@return boolean 校验规则是否通过
function mac_rule:check_rule(source_ip)
    -- 字符串长度为0不校验
    if (not self.m_rule) or string.len(self.m_rule) == 0 then
        return true
    end
    -- ipv6格式检查，通过返回0
    if network_core.verify_ipv6_address(source_ip) == 0 then
        return true
    end
    -- ipv4格式检查，不通过返回-1
    if network_core.verify_ipv4_address(source_ip) == -1 then
        return false
    end

    local eth = get_eth_name()
    return mac_rule.rule_format_type_map[self.m_rule_type].check_rule(self.m_rule, source_ip, eth)
end

--- 检查MAC规则合法性，格式如下：
--- xx:xx:xx:xx:xx:xx                  len = 17
--- xx:xx:xx                           len = 8
---@param rule string 规则
---@return boolean IP规则是否合法
function mac_rule.check_format(rule)
    -- 字符串长度为0不校验
    if (not rule) or string.len(rule) == 0 then
        return true
    end
    -- MAC规则最长17个字符
    if string.len(rule) > 17 then
        return false
    end

    local format_type = mac_rule.get_format_type(rule)
    if not format_type then
        return false
    end

    return mac_rule.rule_format_type_map[format_type].check_format(rule)
end

--- 获取规则格式类型
---@param rule string
---@return string 规则格式类型
function mac_rule.get_format_type(rule)
    -- 字符串长度为0不校验
    if (not rule) or string.len(rule) == 0 then
        return nil
    end

    if string.match(rule, '^%x+:%x+:%x+:%x+:%x+:%x+$') then
        return 'INTEGRITY'
    elseif string.match(rule, '^%x+:%x+:%x+$') then
        return 'THREE_SEGMENT'
    end

    return nil
end

--- 通过MAC规则获取MAC信息
---@param rule string
---@param format_type string
---@return table MAC信息
function mac_rule.get_mac_info(rule, format_type)
    return table.pack(string.match(rule, mac_rule.rule_format_type_map[format_type].regexp))
end

--- 校验INTEGRITY格式MAC规则格式
---@param rule string
---@return boolean 校验INTEGRITY规则格式是否通过
function mac_rule.check_format_intergrity(rule)
    local mac_info = mac_rule.get_mac_info(rule, 'INTEGRITY')
    for _, mac in ipairs(mac_info) do
        -- mac地址每段长度都为2
        if string.len(mac) ~= 2 then
            return false
        end
    end

    return true
end

--- 校验THREE_SEGMENT格式MAC规则格式
---@param rule string
---@return boolean 校验THREE_SEGMENT规则格式是否通过
function mac_rule.check_format_three_segment(rule)
    local mac_info = mac_rule.get_mac_info(rule, 'THREE_SEGMENT')
    for _, mac in ipairs(mac_info) do
        -- mac地址每段长度都为2
        if string.len(mac) ~= 2 then
            return false
        end
    end

    return true
end

--- 校验两种格式MAC规则
---@param rule string
---@return boolean 校验两种规则是否通过
function mac_rule.check_rule_common(rule, source_ip, eth)
    local source_mac = core.get_mac_by_socket(source_ip, eth)
    return mac_rule.compare_string_prefix(source_mac, rule, string.len(rule))
end

--- 比较字符串前缀是否一致
---@param src string
---@param dest string
---@param len number
---@return boolean 前缀是否一致
function mac_rule.compare_string_prefix(src, dest, len)
    if not src or not dest then
        return false
    end
    src = string.upper(src)
    dest = string.upper(dest)
    if not len then
        return src == dest
    end

    for i = 1, len do
        if string.sub(src, i, i) ~= string.sub(dest, i, i) then
            return false
        end
    end

    return true
end

return mac_rule
