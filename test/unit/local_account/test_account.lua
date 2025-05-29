-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.

local config = require 'common_config'
local enum = require 'class.types.types'
local file_utils = require 'utils.file'

local function table_length(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

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

-- 测试修改用户锁定状态后ipmi文件内容更新
function TestAccount:test_lock_and_unlock_user_check_ipmi_file_should_change()
    local account_info = test_account_info_ctor()
    self.test_account_service:new_account(self.ctx, account_info, false)
    self.test_account_collection:set_account_lock_state(nil, 3, true)
    local ipmi_file = file_utils.open_s(config.IPMI_FILE, "r+")
    local ipmi_info = ipmi_file:read("a")
    ipmi_file:close()
    local lock_state = ipmi_info:match('3:test3:x:1:5:0:1:1:1:0:0:4:x:(%d):0:150:0:0')
    assert(tonumber(lock_state) == 1)
    self.test_account_collection:set_account_lock_state(nil, 3, false)
    ipmi_file = file_utils.open_s(config.IPMI_FILE, "r+")
    ipmi_info = ipmi_file:read("a")
    ipmi_file:close()
    lock_state = ipmi_info:match('3:test3:x:1:5:0:1:1:1:0:0:4:x:(%d):0:150:0:0')
    assert(tonumber(lock_state) == 0)
    -- 恢复操作
    self.test_account_collection:delete_account(self.ctx, 3)
end

-- 新建无权限用户, 用户权限为空
function TestAccount:test_add_noaccess_account_then_account_privileges_should_be_empty()
    local account_info = test_account_info_ctor()
    account_info.role_id = 0
    self.test_account_service:new_account(self.ctx, account_info, false)
    assert(#self.test_account_collection.collection[account_info.id].current_privileges == 0)
    -- 恢复环境
    self.test_account_collection:delete_account(self.ctx, account_info.id)
end