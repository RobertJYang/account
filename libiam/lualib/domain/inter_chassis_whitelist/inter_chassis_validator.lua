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

local base_msg = require 'messages.base'
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local log = require 'mc.logging'
local ip_whitelist = require 'domain.inter_chassis_whitelist.ip_whitelist'

local InterChassisWhitelist = class()

function InterChassisWhitelist:ctor(db)
    self.m_db = db
end

local whitelist_type_map = {
    ['IP'] = ip_whitelist
}

function InterChassisWhitelist:init()
    self.m_collection = {}

    for type, obj in pairs(whitelist_type_map) do
        self.m_collection[type] = obj.new(self.m_db)
    end
end

function InterChassisWhitelist:validate(item)
    for type, validator in pairs(self.m_collection) do
        if not validator:validate(item[type]) then
            log:error("%s white list validate failed", type)
            return false
        end
    end

    return true
end

function InterChassisWhitelist:add(type, item)
    if not self.m_collection[type] then
        error(base_msg.PropertyValueNotInList(type, 'type'))
    end
    self.m_collection[type]:add(item)
end

function InterChassisWhitelist:remove(type, item)
    if not self.m_collection[type] then
        error(base_msg.PropertyValueNotInList(type, 'type'))
    end
    self.m_collection[type]:remove(item)
end

function InterChassisWhitelist:get(type)
    if not self.m_collection[type] then
        error(base_msg.PropertyValueNotInList(type, 'type'))
    end
    return self.m_collection[type]:get()
end

return singleton(InterChassisWhitelist)