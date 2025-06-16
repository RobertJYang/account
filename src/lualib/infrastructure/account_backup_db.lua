-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local Singleton = require 'mc.singleton'
local class = require 'mc.class'
local log = require 'mc.logging'
local base_msg = require 'messages.base'

local account_backup_db = class()
function account_backup_db:ctor(db)
    self.db = db
    local account_backup = db:select(db.ManagerAccountBackup)
    self.account_backup_collection = account_backup:fold(function(account, acc)
        acc[account.Id] = account
        return acc
    end, {})
end

function account_backup_db:new_data(id, account_data, ipmi_data, snmp_data)
    local row_data = self.db.ManagerAccountBackup({
        Id = id,
        ManagerAccountData = account_data,
        IpmiAccountData = ipmi_data,
        SnmpAccountData = snmp_data,
    })
    row_data:save()
    self.account_backup_collection[id] = row_data
end

function account_backup_db:get_data(id)
    if id == nil or id < 2 or id > 17 then
        log:error('get account data failed, the account_id %d is invalid',id)
        error(base_msg.PropertyValueNotInList("id"))
    end
    return self.account_backup_collection[id]
end

--备份前清空备份表数据
function account_backup_db:clear()
    for _ , account in pairs(self.account_backup_collection) do
        self.account_backup_collection[account.Id] = nil
        account:delete()
    end
end

return Singleton(account_backup_db)
