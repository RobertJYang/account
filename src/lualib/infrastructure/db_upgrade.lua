-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local sqlite3 = require 'lsqlite3'
local class = require 'mc.class'
local log = require 'mc.logging'
local db_check = require 'mc.db_size_check'
local custom_messages = require 'messages.custom'
local enum = require 'class.types.types'

--- DBUpgrade类进行数据库升级适配
local db_upgrade = class()
function db_upgrade:ctor(databases)
    self.databases = databases
    self.db_check = db_check.new()
end

function db_upgrade:_select(sql, ...)
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

function db_upgrade:_exec(sql, ...)
    local db = self.databases.db
    local vm = db.db:prepare(sql)
    if ... then
        vm:bind_values(...)
    end
    local ret = vm:step()
    vm:finalize()
    return ret
end

function db_upgrade:_check_account_data_success(row)
    -- 空数据使用默认值，不进行处理
    if not row.AccountType then
        return true
    end
    local ok, err = pcall(function()
        enum.AccountType.new(tonumber(row.AccountType)):validate('AccountType')
    end)
    if not ok then
        log:error('load account data failed, error: %s, Id: %s, AccountType: %s', err, row.Id,
            tostring(row.AccountType))
        error(err)
    end
    return true
end

--- 按行传数据库字段进来
---@param t_name any
---@param row any
---@return boolean
function db_upgrade:recover_db(t_name, row)
    if t_name == 't_manager_account' then
        return self:_check_account_data_success(row)
    else
        return true
    end
end

function db_upgrade:check_trusted_partition_overrun()
    if self.db_check:check_trusted_partition_overrun() then
        error(custom_messages.InsufficientFreeSpace())
    end
    -- 更新持久化分区数据占用情况
    self.db_check:monitor_partition()
    -- 检查远程掉电持久化数据库是否超限
    if self.db_check:get_remote_overrun({'protect_power_off'}) then
        error(custom_messages.InsufficientFreeSpace())
    end
end

return db_upgrade
