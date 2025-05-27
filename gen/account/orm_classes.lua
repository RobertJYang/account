-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local c_object = require 'mc.orm.object'

local orm_classes = {}

function orm_classes.init(db)
    orm_classes.AccountService = c_object('AccountService')
    orm_classes.ManagerAccountDB = c_object('ManagerAccountDB')
    orm_classes.ManagerAccountBackup = c_object('ManagerAccountBackup')
    orm_classes.SNMPUserInfo = c_object('SNMPUserInfo')
    orm_classes.IpmiUserInfo = c_object('IpmiUserInfo')
    orm_classes.HistoryPassword = c_object('HistoryPassword')
    orm_classes.LoginRule = c_object('LoginRule')
    orm_classes.Roles = c_object('Roles')
    orm_classes.Role = c_object('Role')
    orm_classes.SnmpCommunity = c_object('SnmpCommunity')
    orm_classes.AccountBackup = c_object('AccountBackup')
    orm_classes.PasswordPolicy = c_object('PasswordPolicy')
    orm_classes.AccountPolicy = c_object('AccountPolicy')
end

return orm_classes
