-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local enum = require 'class.types.types'
local privilege = require 'domain.privilege'

local function make_interface()
    local interface = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish,
        enum.LoginInterface.SFTP, enum.LoginInterface.SNMP }
    return interface
end

local function test_account_info_ctor()
    local account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    return account_info
end

function TestAccount:test_account_backup_db()
    local v = self.db:select(self.db.AccountBackup):where(self.db.AccountBackup.Id:eq(2)):first()
    lu.assertEquals(self.db.AccountBackup:get_count(), 1)
    lu.assertEquals(v.UserName, 'Administrator')
    lu.assertEquals(v.RoleId, 4)
end

function TestAccount:test_new_account_backup_and_delete()
    -- 创建用户，查看备份表
    local account_id = 3
    local account_info = test_account_info_ctor()
    self.test_account_service:new_account(self.ctx, account_info, false)
    local backup_info = self.test_account_permanent_backup.m_account_backup_collection[account_id]
    lu.assertEquals(backup_info.UserName, 'test3')
    lu.assertEquals(backup_info.RoleId, enum.RoleType.Administrator:value())

    -- 修改信息，查看备份表
    self.test_account_collection:change_user_name(account_id, "test4")
    lu.assertEquals(backup_info.UserName, 'test4')

    -- 恢复环境，查看备份表
    self.test_account_collection:delete_account(self.ctx, account_id)
    assert(self.test_account_permanent_backup.m_account_backup_collection[3] == nil)
end

function TestAccount:test_when_disable_only_admin_should_recover_from_permanent()
    -- 强制关闭2号用户使能
    local account = self.test_account_collection:get_account_by_account_id(2)
    account.m_account_data.Enabled = false
    lu.assertEquals(account:get_enabled(), false)

    -- 触发recover操作
    self.test_account_permanent_backup:recover_permanent_account_info()

    -- 恢复环境，查看备份表
    lu.assertEquals(account:get_enabled(), true)
end

function TestAccount:test_when_no_admin_should_recover_from_permanent()
    -- 强制将2号用户设置为操作员
    local account = self.test_account_collection:get_account_by_account_id(2)
    account.m_account_data.RoleId = 3
    account:update_privileges()

    lu.assertEquals(account:get_role_id(), 3)
    lu.assertEquals(account.current_privileges, privilege.new_from_role_ids({ 3 }):to_array())

    -- 触发recover操作
    self.test_account_permanent_backup:recover_permanent_account_info()

    -- 恢复环境，查看备份表
    lu.assertEquals(account:get_role_id(), 4)
    lu.assertEquals(account.current_privileges, privilege.new_from_role_ids({ 4 }):to_array())
end