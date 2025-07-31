-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Test passwords:[Paswd@90001, Paswd@90000]

local lu = require 'luaunit'
local utils = require 'infrastructure.utils'
local enum = require 'class.types.types'
local mc_utils = require 'mc.utils'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'

local OEM_ACCOUNT_ID<const> = 101   -- oem用户id:101

local function make_interface()
    local interface = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish,
        enum.LoginInterface.SFTP, enum.LoginInterface.SNMP }
    return interface
end

-- 测试增加oem密文用户，该用户为管理员时可以正常管理其他用户
function TestAccount:test_add_oem_administrator_account_should_success()
    local interface = make_interface()
    local account_info = {
        ['id'] = OEM_ACCOUNT_ID,
        ['name'] = "OEMAccount",
        ['password'] = "$1$ftdliuca$LRcjcgfkA88Urj6974q/V0",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['is_pwd_encrypted'] = true,
        ['oem'] = true,
        ['account_type'] = enum.AccountType.OEM:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    local test_account = self.test_account_collection.collection[OEM_ACCOUNT_ID]
    lu.assertEquals(test_account.m_account_data.UserName, "OEMAccount")
    lu.assertEquals(test_account.m_account_data.AccountType, enum.AccountType.OEM)
    lu.assertEquals(test_account.m_account_data.LoginInterface, utils.cover_interface_enum_to_num(interface))
    account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@90001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['account_type'] = enum.AccountType.OEM:value()
    }
    local tmp_ctx = mc_utils.table_copy(self.ctx)
    self.test_account_collection:new_account(tmp_ctx, account_info, false)
    test_account = self.test_account_collection.collection[3]
    lu.assertEquals(test_account.m_account_data.UserName, "test3")
    self.test_account_collection:delete_account(tmp_ctx, 3)

    -- 恢复环境
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), true)
    self.test_account_collection:delete_account(self.ctx, OEM_ACCOUNT_ID)
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), false)
    test_account = self.test_account_collection.collection[OEM_ACCOUNT_ID]
    lu.assertIsNil(test_account)
end

function TestAccount:test_add_oem_account_interface_and_role_not_writable_should_success()
    local interface = make_interface()
    local account_info = {
        ['id'] = OEM_ACCOUNT_ID,
        ['name'] = "OEMAccount",
        ['password'] = "Paswd@90001",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['oem'] = true,
        ['account_type'] = enum.AccountType.OEM:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    -- 创建成功
    lu.assertNotIsNil(self.test_account_collection.collection[OEM_ACCOUNT_ID])
    local oem_unwritable_pro = {
        LoginInterfaceWritable = false,
        RoleIdWritable = false
    }
    self.test_account_collection:set_account_property_writable(self.ctx, OEM_ACCOUNT_ID, oem_unwritable_pro)
    local interface_str = {'IPMI', 'Web'}
    lu.assertErrorMsgContains(base_msg.PropertyNotWritableMessage.Name, function()
        self.test_account_collection:set_login_interface(self.ctx, OEM_ACCOUNT_ID, interface_str)
    end)
    lu.assertErrorMsgContains(base_msg.PropertyNotWritableMessage.Name, function()
        self.test_account_collection:set_role_id(self.ctx, OEM_ACCOUNT_ID, enum.RoleType.CommonUser:value())
    end)

    -- 恢复环境
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), true)
    self.test_account_collection:delete_account(self.ctx, OEM_ACCOUNT_ID)
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), false)
    lu.assertIsNil(self.test_account_collection.collection[OEM_ACCOUNT_ID])
end

function TestAccount:test_verify_not_pwd_encrypted_oem_account_should_match_success_and_not_match_fail()
    local interface = make_interface()
    local account_info = {
        ['id'] = OEM_ACCOUNT_ID,
        ['name'] = "OEMAccount",
        ['password'] = "Paswd@90001",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['oem'] = true,
        ['is_pwd_encrypted'] = false,
        ['account_type'] = enum.AccountType.OEM:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    -- 创建成功
    lu.assertNotIsNil(self.test_account_collection.collection[OEM_ACCOUNT_ID])
    -- 信息匹配则成功
    local account = self.test_account_collection.collection[account_info.id]
    local ok = pcall(account.verify_account, account, account_info)
    assert(ok)
    -- 信息不匹配则失败
    account_info['password'] = "Paswd@90000"
    lu.assertErrorMsgContains(base_msg.ActionParameterUnknownMessage.Name, function()
        account:verify_account(account_info)
    end)

    -- 恢复环境
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), true)
    self.test_account_collection:delete_account(self.ctx, OEM_ACCOUNT_ID)
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), false)
    lu.assertIsNil(self.test_account_collection.collection[OEM_ACCOUNT_ID])
end

-- 测试校验oem密文密码用户，信息相匹配时应该校验成功，不匹配时应该失败
function TestAccount:test_verify_pwd_encrypted_oem_account_should_match_success_and_not_match_fail()
    local interface = make_interface()
    local account_info = {
        ['id'] = OEM_ACCOUNT_ID,
        ['name'] = "OEMAccount",
        ['password'] = "$1$ftdliuca$LRcjcgfkA88Urj6974q/V0",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['oem'] = true,
        ['is_pwd_encrypted'] = true,
        ['account_type'] = enum.AccountType.OEM:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    -- 创建成功
    lu.assertNotIsNil(self.test_account_collection.collection[OEM_ACCOUNT_ID])
    -- 信息匹配则成功
    local account = self.test_account_collection.collection[account_info.id]
    local ok = pcall(account.verify_account, account, account_info)
    assert(ok)
    -- 信息不匹配则失败
    account_info['password'] = "Paswd@90000"
    lu.assertErrorMsgContains(base_msg.ActionParameterUnknownMessage.Name, function()
        account:verify_account(account_info)
    end)

    -- 恢复环境
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), true)
    self.test_account_collection:delete_account(self.ctx, OEM_ACCOUNT_ID)
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), false)
    lu.assertIsNil(self.test_account_collection.collection[OEM_ACCOUNT_ID])
end

function TestAccount:test_set_long_password_successful()
    -- 1、新建OEM用户
    local interface = make_interface()
    local account_info = {
        ['id'] = OEM_ACCOUNT_ID,
        ['name'] = "OEMAccount",
        ['password'] = "$1$ftdliuca$LRcjcgfkA88Urj6974q/V0",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['oem'] = true,
        ['is_pwd_encrypted'] = true,
        ['account_type'] = enum.AccountType.OEM:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)

    -- 2、校验新建的用户成功
    lu.assertNotIsNil(self.test_account_collection.collection[OEM_ACCOUNT_ID])
    -- 信息匹配则成功
    local account = self.test_account_collection.collection[account_info.id]
    local ok = pcall(account.verify_account, account, account_info)
    assert(ok)

    -- 3、尝试设置长密码(>20)，失败 strlen(Paswd@123456789012345678901234567890) = 36
    local long_passwd = "Paswd@123456789012345678901234567890"
    lu.assertErrorMsgContains(custom_msg.StringValueTooLongMessage.Name, function()
        self.test_account_collection:set_account_password(self.ctx, OEM_ACCOUNT_ID, OEM_ACCOUNT_ID, long_passwd)
    end)

    -- 4、设置OEM用户长密码为40
    self.test_password_validator_collection:set_password_max_length(self.ctx, enum.AccountType.OEM:value(), 40)

    -- 5、尝试设置长密码，成功
    ok = pcall(function()
        self.test_account_collection:set_account_password(self.ctx, OEM_ACCOUNT_ID, OEM_ACCOUNT_ID, long_passwd)
    end)
    assert(ok)

    -- end 恢复环境
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), true)
    self.test_account_collection:delete_account(self.ctx, OEM_ACCOUNT_ID)
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), false)
    lu.assertIsNil(self.test_account_collection.collection[OEM_ACCOUNT_ID])
    self.test_password_validator_collection:set_password_max_length(self.ctx, enum.AccountType.OEM:value(), 20)
end

function TestAccount:test_oem_password_validator()
    -- 1、新建OEM用户
    local interface = make_interface()
    local account_info = {
        ['id'] = OEM_ACCOUNT_ID,
        ['name'] = "OEMAccount",
        ['password'] = "$1$ftdliuca$LRcjcgfkA88Urj6974q/V0",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['oem'] = true,
        ['is_pwd_encrypted'] = true,
        ['account_type'] = enum.AccountType.OEM:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)

    -- 2、校验新建的用户成功
    lu.assertNotIsNil(self.test_account_collection.collection[OEM_ACCOUNT_ID])
    -- 信息匹配则成功
    local account = self.test_account_collection.collection[account_info.id]
    local ok = pcall(account.verify_account, account, account_info)
    assert(ok)

    -- 3、设置不符合密码复杂度的密码，失败
    self.test_global_account_config:set_password_complexity_enable(false)
    lu.assertErrorMsgContains(custom_msg.InvalidPasswordLengthMessage.Name, function()
        self.test_account_collection:set_account_password(self.ctx, OEM_ACCOUNT_ID, OEM_ACCOUNT_ID, '')
    end)

    -- end 恢复环境
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), true)
    self.test_account_collection:delete_account(self.ctx, OEM_ACCOUNT_ID)
    self.test_account_policy_collection:set_deletable(self.ctx, enum.AccountType.OEM:value(), false)
    lu.assertIsNil(self.test_account_collection.collection[OEM_ACCOUNT_ID])
    self.test_global_account_config:set_password_complexity_enable(true)
end