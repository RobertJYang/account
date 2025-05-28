-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Test passwords:[Paswd@9001, Paswd@9005, Paswd@9006, Paswd9005, Paswd_9005, 9005@Paswd]
local lu = require 'luaunit'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'
local enum = require 'class.types.types'

--- 用户名合法，应该检查成功
function TestAccount:test_when_unsername_valid_should_check_success()
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('Administrator'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name(string.rep('A', 16)))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('A#dministrator'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('A+dministrator'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('A-dminis_trator'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('.A..dministrator'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('.A..d_123'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('...!@#$^*()-=+_'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('_={};[]?.'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('[Admin]'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('Ad{mi}n'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name(']Adm;i]n'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('.Admin..'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('_dm=in?'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('[[[Ad}}}min{{'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('|.root|'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('adm|in+1#'))
    lu.assertIsTrue(self.test_account_policy_collection:check_user_name('t1@#!~`$^*()-_+?'))
end

--- 用户名不合法，应该检查失败
function TestAccount:test_when_unsername_invalid_should_check_fail()
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name(''))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('.'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('..'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name(' Administrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name(string.rep('A', 17)))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('A:dministrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('A<dministrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('A>dministrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('A&dministrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('A,dministrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('A"dministrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('A/dministrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('A\\dministrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('A%dministrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('A dministrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('#Administrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('+Administrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('-Administrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('A“dministrator'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('Administrator\r'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('Administrator\n'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('Administrator\f'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('Administrator\r\n\f'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('Administrator\n\n'))
    lu.assertIsFalse(self.test_account_policy_collection:check_user_name('Administrator\f\f'))
end

--- 设置本地用户AllowedLoginInterface合法应成功
function TestAccount:test_set_allowed_login_interfaces_success()
    -- 登录接口num:Web:1, SNMP:2, IPMI:4, SSH:8, SFTP:16, Local:64, Redfish:128
    self.test_account_policy_collection:set_allowed_login_interfaces(1)
    self.test_account_policy_collection:set_allowed_login_interfaces(2)
    self.test_account_policy_collection:set_allowed_login_interfaces(4)
    self.test_account_policy_collection:set_allowed_login_interfaces(8)
    self.test_account_policy_collection:set_allowed_login_interfaces(64)
    self.test_account_policy_collection:set_allowed_login_interfaces(128)
    self.test_account_policy_collection:set_allowed_login_interfaces(80)
    self.test_account_policy_collection:set_allowed_login_interfaces(137)
    self.test_account_policy_collection:set_allowed_login_interfaces(223)
end

--- 设置本地用户AllowedLoginInterface不合法应失败
function TestAccount:test_set_allowed_login_interfaces_invalid_should_failed()
    -- 本地用户禁止关闭所有登录接口/只开启SFTP接口
    lu.assertErrorMsgContains(custom_msg.ArrayPropertyInvalidItemMessage.Name, function ()
        self.test_account_policy_collection:set_allowed_login_interfaces(0)
    end)
    lu.assertErrorMsgContains(custom_msg.ArrayPropertyInvalidItemMessage.Name, function ()
        self.test_account_policy_collection:set_allowed_login_interfaces(16)
    end)
    -- 不支持的登录接口
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function ()
        self.test_account_policy_collection:set_allowed_login_interfaces(32)
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function ()
        self.test_account_policy_collection:set_allowed_login_interfaces(111)
    end)
end

--- 检查登录接口是否在AllowedLoginInterfaces内
function TestAccount:test_check_login_interface_is_allowed()
    -- 137:Web,SSH,Redfish
    self.test_account_policy_collection:set_allowed_login_interfaces(137)
    lu.assertIsTrue(self.test_account_policy_collection:check_login_interface_is_allowed(1))
    lu.assertIsTrue(self.test_account_policy_collection:check_login_interface_is_allowed(8))
    lu.assertIsTrue(self.test_account_policy_collection:check_login_interface_is_allowed(128))
    lu.assertIsTrue(self.test_account_policy_collection:check_login_interface_is_allowed(9))
    lu.assertIsTrue(self.test_account_policy_collection:check_login_interface_is_allowed(137))
    lu.assertIsFalse(self.test_account_policy_collection:check_login_interface_is_allowed(4))
    lu.assertIsFalse(self.test_account_policy_collection:check_login_interface_is_allowed(132))
    lu.assertIsFalse(self.test_account_policy_collection:check_login_interface_is_allowed(16))
    lu.assertIsFalse(self.test_account_policy_collection:check_login_interface_is_allowed(80))
    -- 恢复操作
    self.test_account_policy_collection:set_allowed_login_interfaces(223)
end

--- 获取OEM用户Visible属性
function TestAccount:test_get_oem_account_visible()
    local account_type = enum.AccountType.OEM:value()
    local result = self.test_account_policy_collection:get_visible(account_type)
    lu.assertEquals(result, false)
end

--- 设置OEM用户Visible属性
function TestAccount:test_set_oem_account_visible()
    local account_type = enum.AccountType.OEM:value()
    self.test_account_policy_collection:set_visible(self.ctx, account_type, true)
    local result = self.test_account_policy_collection:get_visible(account_type)
    lu.assertEquals(result, true)
    --恢复环境
    self.test_account_policy_collection:set_visible(self.ctx, account_type, false)
end

--- 获取OEM用户Deletable属性
function TestAccount:test_get_oem_account_deletable()
    local account_type = enum.AccountType.OEM:value()
    local result = self.test_account_policy_collection:get_deletable(account_type)
    lu.assertEquals(result, false)
end

--- 设置OEM用户Deletable属性
function TestAccount:test_set_oem_account_deletable()
    local account_type = enum.AccountType.OEM:value()
    self.test_account_policy_collection:set_deletable(self.ctx, account_type, true)
    local result = self.test_account_policy_collection:get_deletable(account_type)
    lu.assertEquals(result, true)
    --恢复环境
    self.test_account_policy_collection:set_deletable(self.ctx, account_type, false)
end