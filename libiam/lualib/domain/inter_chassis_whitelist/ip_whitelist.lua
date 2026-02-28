-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.

local singleton = require 'mc.singleton'
local class = require 'mc.class'
local BaseWhitelist = require 'domain.inter_chassis_whitelist.base_whitelist'

local IpWhitelist = class(BaseWhitelist)

function IpWhitelist:ctor()
    self.m_type = "IP"
    self.m_whitelist = {}
end

function IpWhitelist:init()
    IpWhitelist.super.init(self)
end

function IpWhitelist:validate(input)
    if not input then
        return false
    end

    for _, item in pairs(self.m_whitelist) do
        if input == item.Item then
            return true
        end
    end

    return false
end

return singleton(IpWhitelist)