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
local sqlite3 = require 'lsqlite3'
local class = require 'mc.class'
local db_check = require 'mc.db_size_check'
local custom_messages = require 'messages.custom'

--- DBUpgrade类进行数据库升级适配
local DBUpgrade = class()
function DBUpgrade:ctor(databases)
    self.databases = databases
    self.db_check = db_check.new()
end

function DBUpgrade:_select(sql, ...)
    local db = self.databases.db
    local vm = db.db:prepare(sql)
    if ... then
        vm:bind_values(...)
    end
    local data = {}
    while vm:step() == sqlite3.ROW do
        local row = vm:get_named_values()
        table.insert(data, row)
    end
    vm:finalize()
    return data
end

function DBUpgrade:_exec(sql, ...)
    local db = self.databases.db
    local vm = db.db:prepare(sql)
    if ... then
        vm:bind_values(...)
    end
    local ret = vm:step()
    vm:finalize()
    return ret
end

--- 按行传数据库字段进来
---@param t_name any
---@param row any
---@return boolean
function DBUpgrade:recover_db(t_name, row)
    return true
end

function DBUpgrade:check_trusted_partition_overrun()
    if self.db_check:check_trusted_partition_overrun() then
        error(custom_messages.InsufficientFreeSpace())
    end
end

return DBUpgrade
