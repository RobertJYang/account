-- Copyright (c) Huawei Technologies Co., Ltd. 2026-2026. All rights reserved.
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
local log = require 'mc.logging'
local base_msg = require 'messages.base'

local BaseWhitelist = class()

local MAX_WHITELIST_COUNT = 10

function BaseWhitelist:ctor(db)
    self.m_db = db
end

function BaseWhitelist:init()
    local white_list =
        self.m_db:select(self.m_db.InterChassisWhitelist):where(self.m_db.InterChassisWhitelist.Type:eq(self.m_type))

    self.m_whitelist = white_list:fold(function(item, collection)
        collection[item.Id] = item
        return collection
    end, {})

    self.m_whitelist_table = white_list.table
end

function BaseWhitelist:validate(input)
end

function BaseWhitelist:check_id_exist(input)
    for _, item in pairs(self.m_whitelist) do
        if input == item.Item then
            return item.Id
        end
    end

    return nil
end

function BaseWhitelist:find_unused_id()
    for i = 1, MAX_WHITELIST_COUNT do
        if not self.m_whitelist[i] then
            return i
        end
    end

    return nil
end

function BaseWhitelist:add(item)
    if item == '' or item == '*' then
        log:error("input item is invalid string")
        error(base_msg.PropertyValueFormatError(item, "Item"))
    end
    if self:check_id_exist(item) then
        return
    end

    local id = self:find_unused_id()
    if not id then
        log:error("%s white list exceeding the limit of the implementation.")
        error(base_msg.CreateLimitReachedForResource())
    end

    self.m_whitelist[id] = self.m_whitelist_table({ Id = id, Type = self.m_type, Item = item})
end

function BaseWhitelist:remove(item)
    if item == '' then
        log:error("input item is empty string")
        error(base_msg.PropertyValueFormatError('', "Item"))
    end

    -- 当传入为'*'时，代表清空本类白名单
    if item == '*' then
        self.m_whitelist = {}
        return
    end

    local id = self:check_id_exist(item)
    if not id then
        return
    end

    local cur_item = self.m_whitelist[id]
    cur_item:delete()
    self.m_whitelist[id] = nil
end

function BaseWhitelist:get()
    local list = {}
    for _, item in pairs(self.m_whitelist) do
        table.insert(list, item.Item)
    end
    return list
end

return singleton(BaseWhitelist)