-- Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
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
local log = require 'mc.logging'
local network_core = require 'network.core'
local base_msg = require 'messages.base'
local client = require 'iam.client'
local iam_core = require 'iam_core'

require 'bmc_network.json_types.EthernetInterfaces'

local PATH_ETHERNET<const> = '/bmc/kepler/Managers/1/EthernetInterfaces'

local mac_rule = class()

--- 比较字符串前缀是否一致
---@param src string
---@param dest string
---@param len number
---@return boolean 前缀是否一致
local function compare_string_prefix(src, dest, len)
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

function mac_rule:ctor(rule)
    self.m_rule = rule -- 规则内容
end

--- 设置规则
---@param rule string 规则
---@return string 规则
function mac_rule:set_rule(rule)
    self.m_rule = rule
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
    local source_mac = iam_core.get_mac_by_socket(source_ip, eth)
    return compare_string_prefix(source_mac, self.m_rule, string.len(self.m_rule))
end

return mac_rule
